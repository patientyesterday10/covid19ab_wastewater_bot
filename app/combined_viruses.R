####################################################################################################
# Combined Wasterwater Data for Alberta
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

plot_data[,norm_val:=(n1_n2_mean_ma-min(n1_n2_mean_ma,na.rm=T))/(max(n1_n2_mean_ma,na.rm=T)-min(n1_n2_mean_ma,na.rm=T)),by=c("location","data_type")]

covid_data <- copy(plot_data)


# Influenza A -------------------------------------------------------------

ab_wastewater <- rbindlist(
  lapply(
    jsonlite::read_json("https://covid-tracker-json.s3.us-west-2.amazonaws.com/influenzaData.json")$data,
    FUN = function(x){
      data.table(t(unlist(as.vector(x))))
    }), fill = TRUE)
ab_wastewater[,date:=as.Date(date),]
ab_wastewater[,inf_a_mean:=as.numeric(inf_a_mean),]
ab_wastewater[,inf_b_mean:=as.numeric(inf_b_mean),]

ab_wastewater[,location:=stringr::str_replace_all(location, " Wastewater Treatment Plant", " WT Plant")]

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
    cols=c("inf_a_mean","inf_b_mean"),
    window=7)
  df$location = x['location']
  return(df)
}))


#dt_ma[,date:=as.Date(date,origin=as.Date("1970-01-01"))]
setnames(dt_ma,c("inf_a_mean","inf_b_mean"),c("inf_a_mean_ma","inf_b_mean_ma"))

plot_data <- merge(dt, dt_ma, by=c("location","date"),all=T)

plot_data[,inf_a_mean_ma:=zoo::na.locf(inf_a_mean_ma,na.rm=F),by=c("location")]
plot_data[,inf_b_mean_ma:=zoo::na.locf(inf_b_mean_ma,na.rm=F),by=c("location")]

plot_data[,norm_val:=(inf_a_mean_ma-min(inf_a_mean_ma,na.rm=T))/(max(inf_a_mean_ma,na.rm=T)-min(inf_a_mean_ma,na.rm=T)),by=c("location")]

infa_data <- copy(plot_data)



# RSV Data ----------------------------------------------------------------

ab_wastewater <- rbindlist(
  lapply(
    jsonlite::read_json("https://covid-tracker-json.s3.us-west-2.amazonaws.com/rsv.json")$data,
    FUN = function(x){
      data.table(t(unlist(as.vector(x))))
    }), fill = TRUE)
ab_wastewater[,date:=as.Date(date),]
ab_wastewater[,rsv_mean:=as.numeric(rsv_mean),]

ab_wastewater[,location:=stringr::str_replace_all(location, " Wastewater Treatment Plant", " WT Plant")]

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

plot_data[,norm_val:=(rsv_mean_ma-min(rsv_mean_ma,na.rm=T))/(max(rsv_mean_ma,na.rm=T)-min(rsv_mean_ma,na.rm=T)),by=c("location")]

rsv_data <- copy(plot_data)



# Combine -----------------------------------------------------------------

combined <- merge(
  merge(
    covid_data[,list(location,date,`SARS-CoV-2`=norm_val)],
    infa_data[,list(location,date,`Influenza A`=norm_val)],
    by=c("location","date")),
  rsv_data[,list(location,date,RSV=norm_val)],
  by=c("location","date"))

unique(combined$location)

plot_data <- melt(combined,id.vars = c("location","date"))

ggplot(plot_data[location=="Bonnybrook WT Plant",],aes(x=date,y=value,colour=variable))+
  geom_line(lwd=0.8)+
  geom_point()+
  theme_bw()+
  labs(title="Bonnybrook (Calgary): COVID19, Influenza A, and RSV",subtitle = "Values normalized between 0-1",caption = "Data Source: CHI-CSM, University of Calgary")


p <- ggplot(plot_data[date>=Sys.Date()-90,],aes(x=date,y=value,colour=variable))+
  geom_line()+
  facet_wrap(~location)+
  theme_bw()+
  labs(title="Alberta: COVID19, Influenza A, and RSV",subtitle = "Values normalized between 0-1",caption = "Data Source: CHI-CSM, University of Calgary")+
  ylab("Normalized Value (0-1)")+
  scale_x_date(name="Date",date_breaks="3 months", date_minor_breaks = "1 month",date_labels = "%b")+
  scale_color_discrete(name="Virus")

ggsave(filename = paste0("output/ab_viruses.png"),plot = p, width=8,height=8,units = "in",dpi=150)


p <- ggplot(plot_data[location %in% c("Bonnybrook WT Plant","Pine Creek WT Plant","Fish Creek WT Plant")],aes(x=date,y=value,colour=variable))+
  geom_line()+
  facet_grid(location~.)+
  theme_bw()+
  labs(title="Calgary: COVID19, Influenza A, and RSV",subtitle = "Values normalized between 0-1",caption = "Data Source: CHI-CSM, University of Calgary")+
  ylab("Normalized Value (0-1)")+
  scale_x_date(name="Date",date_breaks="3 months", date_minor_breaks = "1 month",date_labels = "%b")+
  scale_color_discrete(name="Virus")

ggsave(filename = paste0("output/calgary_viruses.png"),plot = p, width=8,height=8,units = "in",dpi=150)
