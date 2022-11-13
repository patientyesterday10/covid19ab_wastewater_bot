####################################################################################################
# COVID19 Wasterwater Data for Alberta
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
    jsonlite::read_json(
      "https://covid-tracker-json.s3.us-west-2.amazonaws.com/wasteWaterAbData.json")$data,
    FUN = function(x){
      data.table(t(unlist(as.vector(x))))
    }))
ab_wastewater[,date:=as.Date(date),]
ab_wastewater[,n1_mean:=as.numeric(n1_mean)]
ab_wastewater[,n2_mean:=as.numeric(n2_mean)]
ab_wastewater[,n1_n2_mean:=(n1_mean+n2_mean)/2]
ab_wastewater[,location:=stringr::str_replace_all(string = location,"Wastewater Treatment Plant","WT Plant")]
ab_wastewater[location=="Fort Saskatchewan",location:="Capital Reg."]
setorder(ab_wastewater,date)

dt <- copy(ab_wastewater)

# Calculate 3-observation rolling average:
get_ma <- function(dt,cols,window=14){
  return(setDT(dt)[SJ(date = (min(date) + window):(max(date)))[, c("start", "end") := .(date - window, date)],
                   on = .(date > start, date <= end),
                   c(.(date = as.Date(i.date,origin="1970-01-01")), lapply(.SD, mean, na.rm=T)), .SDcols = cols, by = .EACHI][,-(1:2)])
}

dt_ma = rbindlist(apply(unique(dt[,list(location,data_type)]),MARGIN = 1,FUN = function(x){
  df = dt[location==x['location'] & data_type==x['data_type'],]

  df = get_ma(
    dt = df,
    cols=c("n1_mean","n2_mean","n1_n2_mean"),
    window=7)
  df$location = x['location']
  df$data_type = x['data_type']
  return(df)
}))


#dt_ma[,date:=as.Date(date,origin=as.Date("1970-01-01"))]
setnames(dt_ma,c("n1_mean","n2_mean","n1_n2_mean"),c("n1_mean_ma","n2_mean_ma","n1_n2_mean_ma"))

plot_data <- merge(dt, dt_ma, by=c("location","data_type","date"),all=T)
preferred_data_type <- plot_data[date>=as.Date("2022-01-01"),list(data_type="raw"),by=c("location")]
plot_data <- merge(plot_data,preferred_data_type,by=c("location","data_type"))

plot_data[!is.finite(n1_n2_mean_ma) & is.finite(n1_n2_mean),n1_n2_mean_ma:=n1_n2_mean,]
plot_data[,n1_n2_mean_ma:=zoo::na.locf(n1_n2_mean_ma,na.rm=F),by=c("location")]
plot_data[,n1_mean_ma:=zoo::na.locf(n1_mean_ma,na.rm=F),by=c("location")]
plot_data[,n2_mean_ma:=zoo::na.locf(n2_mean_ma,na.rm=F),by=c("location")]

plot_data[is.finite(n1_n2_mean_ma),p_value:=rank(n1_n2_mean_ma)/sum(ifelse(is.finite(n1_n2_mean_ma),1,0)),by=c("location","data_type")]
plot_data[n1_mean<1e-4,n1_mean:=NA]
plot_data[n2_mean<1e-4,n2_mean:=NA]

plot_data[,lowval:=ifelse(n1_mean<=n2_mean,n1_mean,n2_mean)]
plot_data[,highval:=ifelse(n1_mean>=n2_mean,n1_mean,n2_mean)]

plot_data[,max_date:=max(date),by="location"]
plot_data[,last_perc:=mean(ifelse(date==max_date,p_value,NA),na.rm=T),by=c("location")]
plot_data[,location_label:=paste0(location," (P",round(last_perc*100,0),", ", strftime(max_date,"%b %e") ,")")]

p <- ggplot(plot_data[date>=Sys.Date()-90 & !grepl("WT Plant",location),],aes(x=date))+
  geom_col(aes(y=n1_n2_mean_ma,fill=p_value))+
  geom_point(data=plot_data[date>=Sys.Date()-90 & !grepl("WT Plant",location) & date>=max_date-7,],
             aes(y=n1_mean,shape="N1"),colour="grey30",alpha=0.75,size=1)+
  geom_point(data=plot_data[date>=Sys.Date()-90 & !grepl("WT Plant",location) & date>=max_date-7,],
             aes(y=n2_mean,shape="N2"),colour="grey30",alpha=0.75,size=1)+
  geom_step(aes(y=n1_n2_mean_ma),colour="black",lwd=0.8)+
  facet_wrap(location_label~.,scales="free_y")+
  theme_bw()+
  theme(axis.text.y=element_blank(),axis.ticks.y=element_blank(),legend.position = 'bottom',
        strip.text = element_text(size=rel(0.6)))+
  scale_y_continuous("SARS-CoV-2 RNA Flux (Avg of N1,N2)")+
  xlab(NULL)+
  scale_fill_viridis_c(option = "viridis",name="Percentile")+
  scale_color_discrete(name=NULL)+
  scale_shape_discrete(name=NULL)+
  coord_cartesian(ylim=c(0,NA))+
  labs(title="Alberta COVID19 Wastewater Trends",
       subtitle=paste0("Latest sample as of ",max(plot_data$date)),
       caption="Percentile (PXX) indicates fraction of days below the most recent value for each location\nData Source: Centre for Health Informatics, Cumming School of Medicine, University of Calgary")

ggsave(filename = paste0("output/ab_wastewater.png"),plot = p, width=8,height=8,units = "in",dpi=150)

p_calgary1 <- ggplot(plot_data[location %in% c("Calgary")],aes(x=date))+
  geom_col(aes(y=n1_n2_mean_ma,fill=p_value))+
  geom_line(aes(y=n1_mean_ma,colour="N1 (MA)"),na.rm = T)+
  geom_point(aes(y=n1_mean,shape="N1"),colour="grey50",alpha=0.8,size=1)+
  geom_line(aes(y=n2_mean_ma,colour="N2 (MA)"),na.rm=T)+
  geom_point(aes(y=n2_mean,shape="N2"),colour="grey50",alpha=0.8,size=1)+
  geom_step(aes(y=n1_n2_mean_ma),colour="black",lwd=0.8)+
  facet_wrap(location_label~.,scales="free_y")+
  theme_bw()+
  theme(axis.text.y=element_blank(),axis.ticks.y=element_blank())+
  xlab(NULL)+
  scale_y_continuous("SARS-CoV-2 RNA Flux")+
  scale_fill_viridis_c(option = "viridis",name="Percentile")+
  scale_shape_discrete(name=NULL)+
  scale_colour_discrete(name=NULL)+
  coord_cartesian(ylim=c(0,NA))+
  labs(title="Calgary COVID19 Wastewater Trends",
       subtitle=paste0("Latest sample as of ",max(plot_data[location %in% c("Calgary"),]$date)))

p_calgary2 <- ggplot(plot_data[location %in% c("Bonnybrook WT Plant", "Fish Creek WT Plant", "Pine Creek WT Plant")],aes(x=date))+
  geom_col(aes(y=n1_n2_mean_ma,fill=p_value))+
  geom_line(aes(y=n1_mean_ma,colour="N1 (MA)"),na.rm = T)+
  geom_point(aes(y=n1_mean,shape="N1"),colour="grey50",alpha=0.8,size=1)+
  geom_line(aes(y=n2_mean_ma,colour="N2 (MA)"),na.rm=T)+
  geom_point(aes(y=n2_mean,shape="N2"),colour="grey50",alpha=0.8,size=1)+
  geom_step(aes(y=n1_n2_mean_ma),colour="black",lwd=0.8)+
  facet_wrap(location_label~.,scales="free_y")+
  theme_bw()+
  theme(axis.text.y=element_blank(),axis.ticks.y=element_blank())+
  xlab(NULL)+
  scale_y_continuous("SARS-CoV-2 RNA Flux (Avg of N1,N2)")+
  scale_x_date(date_breaks="1 year", date_labels="%Y", date_minor_breaks="3 months")+
  scale_fill_viridis_c(option = "viridis",name="Percentile",guide="none")+
  scale_shape_discrete(name=NULL)+
  scale_colour_discrete(name=NULL)+
  coord_cartesian(ylim=c(0,NA))+
  labs(caption="Percentile (PXX) indicates fraction of days below the latest value for each location\nData Source: Centre for Health Informatics, Cumming School of Medicine, University of Calgary")


ggsave(filename = paste0("output/calgary_wastewater.png"),
       plot = p_calgary1 / p_calgary2 + plot_layout(nrow=2,heights=c(2,1),guides='collect'),
       width=10,height=8,units = "in",dpi=150)


p_edmonton <- ggplot(plot_data[location %in% c("Edmonton")],aes(x=date))+
  geom_col(aes(y=n1_n2_mean_ma,fill=p_value))+
  geom_line(aes(y=n1_mean_ma,colour="N1 (MA)"),na.rm = T)+
  geom_point(aes(y=n1_mean,shape="N1"),colour="grey50",alpha=0.8,size=1)+
  geom_line(aes(y=n2_mean_ma,colour="N2 (MA)"),na.rm=T)+
  geom_point(aes(y=n2_mean,shape="N2"),colour="grey50",alpha=0.8,size=1)+
  geom_step(aes(y=n1_n2_mean_ma),colour="black",lwd=0.8)+
  facet_wrap(location_label~.,scales="free_y")+
  theme_bw()+
  theme(axis.text.y=element_blank(),axis.ticks.y=element_blank())+
  xlab(NULL)+
  scale_y_continuous("SARS-CoV-2 RNA Flux (Avg of N1,N2)")+
  scale_fill_viridis_c(option = "viridis",name="Percentile")+
  scale_shape_discrete(name=NULL)+
  coord_cartesian(ylim=c(0,NA))+
  labs(title="Edmonton COVID19 Wastewater Trends",
       subtitle=paste0("Latest sample as of ",max(plot_data[location %in% c("Edmonton"),]$date)),
       caption="Percentile (PXX) indicates fraction of days below the latest value for each location\nData Source: Centre for Health Informatics, Cumming School of Medicine, University of Calgary")

ggsave(filename = paste0("output/edmonton_wastewater.png"),
       plot = p_edmonton,
       width=10,height=8,units = "in",dpi=150)


p_data <- unique(plot_data[!grepl(".+WT Plant",location,perl=T),list(location,max_date,last_perc),])
setorder(p_data,last_perc)

p_data[,label:=paste0(location," (",strftime(max_date, "%b %e"),")")]
p_data[,location:=factor(location,levels=p_data$location,labels = p_data$label)]
p_data[,label_colour:=ifelse(last_perc>=0.55,ifelse(last_perc>0.85,"#ff0000","#000000"),"#ffffff")]

p_table <- ggplot(p_data,aes(y=location,x=1))+geom_tile(aes(fill=last_perc))+
  scale_fill_viridis_c(option = "viridis",name="Percentile",values = c(0,1))+
  geom_text(aes(label=formatC(last_perc,digits=2,format='f')),colour=p_data$label_colour)+
  ylab("Location")+
  xlab("Quantile")+
  theme(axis.text.x =element_blank(), axis.ticks.x=element_blank(),legend.position = "none")+
  labs(title="COVID19 Wastewater",
       subtitle="Quantile by Location",
            caption="Quantile: fraction of days below the latest value for each location\nData Source: Centre for Health Informatics, Cumming School of Medicine, University of Calgary")


ggsave(filename = paste0("output/percentile_table.png"),
       plot = p_table,
       width=550,height=425,units = "px",dpi=100)


# Calculate if values are increasing or decreasing by location in past 10 days:
location_trends <- plot_data[!grepl(".+WT Plant", location, perl=T) & date>(max_date-10),list(location,date,n1_n2_mean,n1_n2_mean_ma,last_perc)]
location_trends[,day:=as.numeric(date-min(date)),by=c("location")]
location_trends[,trend_param:=ifelse(is.na(n1_n2_mean),n1_n2_mean_ma, n1_n2_mean)]

# Debugging (look at plots):
# ggplot(location_trends,aes(x=day))+
#   geom_line(aes(y=trend_param,colour="Trend"))+
#   geom_line(aes(y=n1_n2_mean_ma,colour="MA"))+
#   geom_point(aes(y=n1_n2_mean,colour="Mean"))+
#   facet_wrap(~location,scales="free_y")

# Use kendall correlation with days to determine trend:
location_trends <- location_trends[,list(trend=cor(day,n1_n2_mean_ma,method="kendall",use="pairwise.complete.obs"),last_perc=mean(last_perc)),by=c("location")]
location_trends[,trend_label:=ifelse(trend>0.3,"increasing",ifelse(trend<(-0.3),"decreasing","stable"))]

# Categorize current levels based on percentiles:
location_trends[,value_label:=ifelse(last_perc>=0.85,"Very high",
                                     ifelse(last_perc>0.70,"High",
                                            ifelse(last_perc>0.55,"Moderate",
                                                   ifelse(last_perc>0.40,"Low","Very low"))))]
location_trends <- location_trends[,list(location, value_label, trend_label, percentile = paste0(round(last_perc,2)*100,"%")),]
setorder(location_trends,-percentile)

write.csv(location_trends,file="output/location_trends.csv",row.names=FALSE)

writeLines(
  paste0(location_trends[,list(label=paste0(" - ",location,": ", value_label, " (",percentile,"), trend ", trend_label)),]$label, collapse="\n"),
    con="output/location_trends.txt")

# Create markdown table of location trends:
if (require(knitr)) {
  setnames(location_trends, c("location", "value_label", "trend_label", "percentile"), c("Location", "Level", "Trend", "Percentile"))
  location_table <- knitr::kable(location_trends,format = "markdown",align = c("l","c","c","c"),caption = "Summary of level and trend by Location")
  writeLines(location_table, con="output/location_trends.md")
  print(location_table)
}

print("====== DONE ======")