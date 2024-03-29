### https://mastering-shiny.org/index.html
### https://rstudio.github.io/leaflet/shiny.html
### https://stackoverflow.com/questions/53016404/advantages-of-reactive-vs-observe-vs-observeevent
### https://www.r-bloggers.com/2016/03/r-shiny-leaflet-using-observers/
### https://shiny.rstudio.com/articles/layout-guide.html
### https://shiny.rstudio.com/articles/shinyapps.html
### https://beta.rstudioconnect.com/content/2671/Combining-Shiny-R-Markdown.html
### https://resources.symbolix.com.au/2020/10/28/downloadable-reports-shiny/
### https://stefanengineering.com/2019/08/31/dynamic-r-markdown-reports-with-shiny/

library(DT)
library(leaflet)
library(lubridate)
library(rmarkdown)
library(shiny)

# files_wd <- '~/Desktop/professional/projects/Postdoc_FL/data/FCWC/processed'
# setwd(files_wd)
# interp <- read.csv('aquatroll_data_interp.csv')
# data <- read.csv('all_report_shiny3.csv')
files_wd <- '~/Documents/R/Github/HABS-hypoxia'
setwd(files_wd)
# stations <- read.csv('data/stations_data.csv')
data <- read.csv('data/ctd_data.csv',check.names = F)
data$Date <- ymd(data$Date)
min.Date <- as.Date(min(data$Date))

t_col <- colorRampPalette(c(1,'purple','darkorange','gold'))
t_breaks <- seq(13.5,33,by=.5)
t_cols <- t_col(length(t_breaks))
s_col <- colorRampPalette(c('purple4','dodgerblue4','seagreen3','khaki1'))
s_breaks <- seq(28,38,by=.5)
s_cols <- s_col(length(s_breaks))
ox.col1 <- colorRampPalette(c('darkred','red2','sienna1'))
ox.col2 <- colorRampPalette(c('darkgoldenrod4','goldenrod2','gold'))
# ox.col3 <- colorRampPalette(c('dodgerblue4','deepskyblue2','cadetblue1'))
ox.col3 <- colorRampPalette(c('gray20','gray60','gray90'))
o_breaks <- seq(0,11,by=.5)
o_cols <- c(ox.col1(length(o_breaks[o_breaks<2])),
            ox.col2(length(o_breaks[o_breaks>=2 & o_breaks<3.5])),
            ox.col3(length(o_breaks[o_breaks>=3.5])-1))


### ------------ ui ------------
ui <- fluidPage(
  tabsetPanel( tabPanel("Data Visualization",
                        titlePanel("FCWC Data Explorer"),
                        sidebarLayout( 
                          sidebarPanel(
                            dateRangeInput("daterange1", "Date range:",
                                           start  = min.Date,
                                           end    = NULL,
                                           min    = min.Date,
                                           max    = NULL,
                                           format = "yyyy-mm-dd",
                                           separator = " - "),
                            selectInput('parameter', 'Parameter', names(data)[4:7], selected='Bottom Dissolved Oxygen'),
                            # selectInput('project', 'project', c('all',sort(unique(data$project)))),
                            radioButtons('format', 'Document format', c('PDF', 'HTML', 'Word'),
                                         inline = TRUE),
                            downloadButton('downloadReport'),
                            width = 3
                          ),
                          mainPanel(
                            h6('Click on any point on the map and the data will pop up and depth profiles will be displayed below map'),
                            leafletOutput("map",height=600),
                            verbatimTextOutput("map_marker_click"),
                            hr(),
                            h3('Time series plot'),
                            h6('Click on any point below and the the data will be displayed below the plot'),
                            plotOutput(outputId = "ts_plot", click = "plot_click"),
                            verbatimTextOutput("info"),
                            hr(),
                            h3('Climatology plot'),
                            h6('Click on any point below and the the data will be displayed below the plot'),
                            plotOutput(outputId = "boxplot", click = "plot_click2"),
                            verbatimTextOutput("info2"),
                            hr()
                            # h3('Data table'),
                            # tableOutput("table")
                          )
                        )), 
               tabPanel("Feedback",
                        titlePanel("Feedback"),
                        # textInput("name", "Name (optional)", ""),
                        # textInput("email", "Email (optional)", ""),
                        # textInput("feedback", "Please provide comments, concerns, or errors",
                        #           placeholder = 'Type response here'),
                        # actionButton("submit", "Submit", class = "btn-primary"))
                        helpText(a("Click Here if Google Form is not displayed below to submit a comment, question, concern, or report an error",
                                   href="https://docs.google.com/forms/d/e/1FAIpQLSdpXTKQ1uZC-bjYZ-E6wO8Z43GgCf0OSV5WNPglQrY2_TKqmQ/viewform?usp=sf_link")),
                        HTML('<iframe src="https://docs.google.com/forms/d/e/1FAIpQLSdpXTKQ1uZC-bjYZ-E6wO8Z43GgCf0OSV5WNPglQrY2_TKqmQ/viewform?embedded=true" width="640" height="729" frameborder="0" marginheight="0" marginwidth="0">Loading…</iframe>')
               ),
               tabPanel("Disclaimer",
                        titlePanel('Disclaimer'),
                        h5('The data presented here is subject to further review and quality control. The data may be used for informational purposes and is not intended for legal use, since it may contain inaccuracies. Neither the data Contributor, CIMAS, NOAA, nor the United States Government, nor any of their employees or contractors, makes any warranty, express or implied, including warranties of merchantability and fitness for a particular purpose, or assumes any legal liability for the accuracy, completeness, or usefulness, of this information.')
               )
  )
)


### ------------ server ------------ 
server <- function(input, output, session) {
  
  out <- reactive({
    # if(input$project=='all'){
      data[which(data$Date>=ymd(input$daterange1[1]) &
                   data$Date<=ymd(input$daterange1[2])),
           # which(names(data)==input$parameter)
      ]
    # } else {
    #   data[which(data$Date>=ymd(input$daterange1[1]) &
    #                data$Date<=ymd(input$daterange1[2]) & 
    #                data$project==input$project),
    #        # which(names(data)==input$parameter)
    #   ]
    # }
  })
  
  output$ts_plot <- renderPlot({
    if(input$parameter=='Mixed-layer Temperature'){
      t_i <- as.numeric(cut(out()$'Mixed-layer Temperature',t_breaks))
      bg <- t_cols[t_i]
      parm <- out()$'Mixed-layer Temperature'
      ylab <- 'Mixed-layer Temperature (C)'
    }
    if(input$parameter=='Mixed-layer Salinity'){
      s_i <- as.numeric(cut(out()$'Mixed-layer Salinity',s_breaks))
      bg <- s_cols[s_i]
      parm <- out()$'Mixed-layer Salinity'
      ylab <- 'Mixed-layer Salinity (psu)'
    }
    if(input$parameter=='Bottom Temperature'){
      t_i <- as.numeric(cut(out()$'Bottom Temperature',t_breaks))
      bg <- t_cols[t_i]
      parm <- out()$'Bottom Temperature'
      ylab <- 'Bottome Temperature (C)'
    }
    if(input$parameter=='Bottom Dissolved Oxygen'){
      o_i <- as.numeric(cut(out()$'Bottom Dissolved Oxygen',o_breaks))
      bg <- o_cols[o_i]
      parm <- out()$'Bottom Dissolved Oxygen'
      ylab <- 'Bottom Dissolved Oxygen (mg/l)'
    }
    
    plot(out()$Date,parm,
         xlab='Date',ylab=ylab,
         las=2,bg=bg,pch=21,cex=1.5)
    abline(v=as.POSIXct(seq(ymd('2018-01-01'),ymd('2030-01-01'),'month'), origin = "1970-01-01"),lty=3)
    # abline(h=c(3.5,2),col=c('gold4','red'),lty=2,lend=2)
    
  })
  
  output$boxplot <- renderPlot({
    
    if(input$parameter=='Mixed-layer Temperature'){
      t_i <- as.numeric(cut(out()$'Mixed-layer Temperature',t_breaks))
      bg <- t_cols[t_i]
      all_y <- data$`Mixed-layer Temperature`
      ylab <- 'Mixed-layer Temperature (C)'
      select_y <- out()$`Mixed-layer Temperature`
    }
    if(input$parameter=='Mixed-layer Salinity'){
      s_i <- as.numeric(cut(out()$'Mixed-layer Salinity',s_breaks))
      bg <- s_cols[s_i]
      all_y <- data$`Mixed-layer Salinity`
      ylab <- 'Mixed-layer Salinity (psu)'
      select_y <- out()$`Mixed-layer Salinity`
    }
    if(input$parameter=='Bottom Temperature'){
      t_i <- as.numeric(cut(out()$'Bottom Temperature',t_breaks))
      bg <- t_cols[t_i]
      all_y <- data$`Bottom Temperature`
      ylab <- 'Bottome Temperature (C)'
      select_y <- out()$'Bottom Temperature'
    }
    if(input$parameter=='Bottom Dissolved Oxygen'){
      o_i <- as.numeric(cut(out()$'Bottom Dissolved Oxygen',o_breaks))
      bg <- o_cols[o_i]
      all_y <- data$'Bottom Dissolved Oxygen'
      ylab <- 'Bottom Dissolved Oxygen (mg/l)'
      select_y <- out()$'Bottom Dissolved Oxygen'
    }
    
    boxplot(all_y~month(data$Date),na.action = na.pass,
            xlab='Month',ylab=ylab,col='lightskyblue1',
            staplewex=0,outwex=0,outline=F,lty=1,lwd=1.5,names=month.abb[1:12],las=2,
            ylim=c(0,11))
    # mtext('Climatology Plot',cex=2,adj=0,font=2,line=1)
    points(jitter(month(out()$Date),3,.3),select_y,
           bg=bg,pch=21,cex=1.5)
    
  })
  
  output$map <- renderLeaflet({
    
    # basemap <- providers$Esri.NatGeoWorldMap
    basemap <- providers$Esri.OceanBasemap
    # basemap <- providers$CartoDB.Positron
    # basemap <- providers$Esri.WorldImagery
    # basemap <- providers$Esri.WorldTopoMap
    
    leaflet(data = out()) %>% 
      addProviderTiles(basemap) %>% 
      fitBounds(~min(Longitude), ~min(Latitude), ~max(Longitude), ~max(Latitude))
  })
  
  observe({
    
    if(input$parameter=='Mixed-layer Temperature'){
      t_i <- as.numeric(cut(out()$'Mixed-layer Temperature',t_breaks))
      cols <- t_cols[t_i]
      unit <- 'Temperature (C):'
      vals <- round(out()$'Mixed-layer Temperature',2)
      ext <- 1/2
    }
    if(input$parameter=='Mixed-layer Salinity'){
      s_i <- as.numeric(cut(out()$'Mixed-layer Salinity',s_breaks))
      cols <- s_cols[s_i]
      unit <- 'Salinity (psu):'
      vals <- round(out()$'Mixed-layer Salinity',2)
      ext <- 1/2
    }
    if(input$parameter=='Bottom Temperature'){
      t_i <- as.numeric(cut(out()$'Bottom Temperature',t_breaks))
      cols <- t_cols[t_i]
      unit <- 'Temperature (C):'
      vals <- round(out()$'Bottom Temperature',2)
      ext <- 1/2
    } 
    if(input$parameter=='Bottom Dissolved Oxygen'){
      o_i <- as.numeric(cut(out()$'Bottom Dissolved Oxygen',o_breaks))
      cols <- o_cols[o_i]
      unit <- 'DO (mg/l):'
      vals <- round(out()$'Bottom Dissolved Oxygen',2)
      ext <- 2.5
    }
    
    leafletProxy("map", data = out()) %>%
      clearMarkers() %>%
      addCircleMarkers(~Longitude, ~Latitude,
                       # radius = vals*ext,
                       fillColor = cols,
                       stroke = T,
                       color='black',
                       weight=1,
                       fillOpacity = 0.4,
                       popup = paste('Date (UTC):',out()$Date,'<br>',
                                     unit,vals))#,
    # clusterOptions = T)
    # }
    
  })
  
  observe({
    if(input$parameter=='Mixed-layer Temperature'){
      os <- colorBin(t_cols,t_breaks,bins=t_breaks[seq(1,16,2)])
      values <- out()$'Mixed-layer Temperature'
      title <- 'Temperature (C)'
    }
    if(input$parameter=='Mixed-layer Salinity'){
      os <- colorBin(s_cols,s_breaks,bins=s_breaks[seq(1,16,2)])
      values <- out()$'Mixed-layer Salinity'
      title <- 'Salintiy (psu)'
    }
    if(input$parameter=='Bottom Temperature'){
      os <- colorBin(t_cols,t_breaks,bins=t_breaks[seq(1,23,2)])
      values <- out()$'Bottom Temperature'
      title <- 'Temperature (C)'
    }
    if(input$parameter=='Bottom Dissolved Oxygen'){
      os <- colorBin(o_cols,o_breaks,bins=o_breaks[seq(1,23,2)])
      values <- out()$'Bottom Dissolved Oxygen'
      title <- 'Oxygen (mg/l)'
    }
    leafletProxy("map", data = out()) %>%
      clearControls() %>%
      addLegend(position = "topright",
                pal = os,
                values = values,
                title = title,
                opacity = 1)
  })
  
  # output$table <- renderTable({
  #   out <- out()[order(out()$Date),]
  #   if(input$parameter=='Surface.Temperature'){
  #     dat <- data.frame('Date'=as.character(out$Date),
  #                       'Serial Number'=out$aquatroll_sn,
  #                       'Surface Temperature (C)'=round(out$Surface.Temperature,2))
  #   }
  #   if(input$parameter=='Bottom.Temperature'){
  #     dat <- data.frame('Date'=as.character(out$Date),
  #                       'Serial Number'=out$aquatroll_sn,
  #                       'Bottom Temperature (C)'=round(out$Bottom.Temperature,2))
  #   }
  #   if(input$parameter=='Surface.Dissolved.Oxygen'){
  #     dat <- data.frame('Date'=as.character(out$Date),
  #                       'Serial Number'=out$aquatroll_sn,
  #                       'Surface Dissolved Oxygen (mg/l)'=round(out$Surface.Dissolved.Oxygen,2))
  #   }
  #   if(input$parameter=='Bottom.Dissolved.Oxygen'){
  #     dat <- data.frame('Date'=as.character(out$Date),
  #                       'Serial Number'=out$aquatroll_sn,
  #                       'Bottom Dissolved Oxygen (mg/l)'=round(out$Bottom.Dissolved.Oxygen,2))
  #   }
  # })
  
  # output$info <- renderText({
  #   if(input$parameter=='Surface.Temperature' | 
  #      input$parameter=='Bottom.Temperature' ){
  #     y_click <- "\nTemperature (C): "
  #   }
  #   if(input$parameter=='Bottom.Dissolved.Oxygen' | 
  #      input$parameter=='Surface.Dissolved.Oxygen' ){
  #     y_click <- "\nDissolved Oxygen (mg/l): "
  #   }
  #   paste0("Date (UTC): ", as.POSIXct(input$plot_click$x, origin = "1970-01-01"),
  #          y_click, round(as.numeric(input$plot_click$y),2))
  # })
  # 
  # output$info2 <- renderText({
  #   if(input$parameter=='Surface.Temperature' | 
  #      input$parameter=='Bottom.Temperature' ){
  #     y_click <- "Temperature (C): "
  #   }
  #   if(input$parameter=='Bottom.Dissolved.Oxygen' | 
  #      input$parameter=='Surface.Dissolved.Oxygen' ){
  #     y_click <- "Dissolved Oxygen (mg/l): "
  #   }
  #   paste0(y_click, round(as.numeric(input$plot_click2$y),2))
  # })
  # 
  # output$map_marker_click <- renderText({
  #   details <- unlist(out()[which(out()$Latitude==input$map_marker_click$Latitude &
  #                                   out()$Longitude==input$map_marker_click$lng),])[6:9]
  #   paste('Surface Temperature (C):',round(as.numeric(details[1]),2),
  #         '\nBottom Temperature (C):',round(as.numeric(details[2]),2),
  #         '\nSurface Dissolved Oxygen (mg/l):',round(as.numeric(details[3]),2),
  #         '\nBottom Dissolved Oxygen (mg/l):',round(as.numeric(details[4]),2))
  # })
  
  output$downloadReport <- downloadHandler(
    filename = function() {
      paste('my-report', sep = '.', switch(
        input$format, PDF = 'pdf', HTML = 'html', Word = 'docx'
      ))
    },
    
    content = function(file) {
      src <- normalizePath('report.Rmd')
      
      # temporarily switch to the temp dir, in case you do not have write
      # permission to the current working directory
      owd <- setwd(tempdir())
      on.exit(setwd(owd))
      file.copy(src, 'report.Rmd', overwrite = TRUE)
      
      out <- render('report.Rmd', switch(
        input$format,
        PDF = pdf_document(), HTML = html_document(), Word = word_document()
      ))
      file.rename(out, file)
    }
  )
  
  
}


### ------------ run app ------------ 
shinyApp(ui, server)
