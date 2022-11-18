
####################################################################################################
# RSV Wasterwater Data for Alberta
####################################################################################################

# Load Packages
library(data.table)
library(jsonlite)
library(ggplot2)
library(patchwork)

# Set working directory / output directory:
setwd("/tmp")
dir.create("/tmp/output")

ab_wastewater <- rbindlist(
lapply(
jsonlite::read_json("https://covid-tracker-json.s3.us-west-2.amazonaws.com/rsv.json")$data,
FUN = function(x){
data.table(t(unlist(as.vector(x))))
}), fill = TRUE)
ab_wastewater[,date:=as.Date(date),]
ab_wastewater[,rsv_mean:=as.numeric(rsv_mean),]

ab_wastewater[,location:=stringr::str_replace_all(location, " Wastewater Treatment Plant", "")]

dt <- copy(ab_wastewater)

# Calculate 3-observation rolling average:
get_ma <- function(dt,cols,window=14){
  return(setDT(dt)[SJ(date = (min(date) + window):(max(date)))[, c("start", "end") := .(date - window, date)],
                   on = .(date > start, date <= end),
                   c(.(date = as.Date(i.date,origin="1970-01-01")), lapply(.SD, mean, na.rm=T)), .SDcols = cols, by = .EACHI][,-(1:2)])
}

dt_ma = rbindlist(apply(unique(dt[,list(location)]),MARGIN = 1,FUN = function(x){
  df = dt[location==x['location'],]

  df = get_ma(
    dt = df,
    cols=c("rsv_mean"),
    window=7)
  df$location = x['location']
  return(df)
}))


#dt_ma[,date:=as.Date(date,origin=as.Date("1970-01-01"))]
setnames(dt_ma,c("rsv_mean"),c("rsv_mean_ma"))

plot_data <- merge(dt, dt_ma, by=c("location","date"),all=T)

plot_data[,rsv_mean_ma:=zoo::na.locf(rsv_mean_ma,na.rm=F),by=c("location")]

plot_data[is.finite(rsv_mean_ma),p_value:=rank(rsv_mean_ma)/sum(ifelse(is.finite(rsv_mean_ma),1,0)),by=c("location")]
plot_data[rsv_mean<1e-4,rsv_mean:=NA]

plot_data[,max_date:=max(date),by="location"]
plot_data[,last_perc:=mean(ifelse(date==max_date,p_value,NA),na.rm=T),by=c("location")]
plot_data[,location_label:=paste0(location," (P",round(last_perc*100,0),", ", strftime(max_date,"%b %e") ,")")]

p <- ggplot(plot_data[date>=Sys.Date()-90 & !grepl("WT Plant",location),],aes(x=date))+
  geom_col(aes(y=rsv_mean_ma,fill=p_value))+
  geom_step(aes(y=rsv_mean_ma),colour="black",lwd=0.8)+
  facet_wrap(location_label~.,scales="free_y")+
  theme_bw()+
  theme(axis.text.y=element_blank(),axis.ticks.y=element_blank(),legend.position = 'bottom',
        strip.text = element_text(size=rel(0.6)))+
  scale_y_continuous("RSV")+
  xlab(NULL)+
  scale_fill_viridis_c(option = "viridis",name="Percentile")+
  scale_color_discrete(name=NULL)+
  scale_shape_discrete(name=NULL)+
  coord_cartesian(ylim=c(0,NA))+
  labs(title="Alberta RSV Wastewater Trends",
       subtitle=paste0("Latest sample as of ",max(plot_data$date)),
       caption="Percentile (PXX) indicates fraction of days below the most recent value for each location\nData Source: Centre for Health Informatics, Cumming School of Medicine, University of Calgary")

ggsave(filename = paste0("output/ab_rsv.png"),plot = p, width=8,height=8,units = "in",dpi=150)
