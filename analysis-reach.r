#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(data.table)
library(doMC)
library(grid)
library(gridExtra)
options(warning=traceback)

doMC::registerDoMC(cores=8)

wideScreen <- function(howWide=Sys.getenv("COLUMNS")) {
	options(width=as.integer(howWide))
}

wideScreen(180)

args <- commandArgs(trailingOnly = TRUE)

# read input data
input <- read.csv(file=args[1], sep=',', na.strings=c(""), quote="\"", row.names=NULL)

input <- input[ grep("-nan", input$NES, invert = TRUE) , ]

input <- subset(input, input$type != "statistics" | (input$type == "statistics" & !is.na(input$NES)))

# rename reordering strategies
input$reordering <- gsub("bs", "Sloan", input$reordering)
input$reordering <- gsub("vgps", "GPS", input$reordering)
input$reordering <- gsub("vacm", "aCM", input$reordering)
input$reordering <- gsub("bk", "King", input$reordering)
input$reordering <- gsub("bcm", "CMB", input$reordering)
input$reordering <- gsub("vcm", "CMV", input$reordering)
input$reordering <- gsub("f", "FORCE", input$reordering)

input$bandwidth[input$reordering == "none" | input$reordering == "Noack1" | input$reordering == "Noack2"] <- NA
input$span[input$reordering == "none" | input$reordering == "Noack1" | input$reordering == "Noack2"] <- NA
input$profile[input$reordering == "none" | input$reordering == "Noack1" | input$reordering == "Noack2"] <- NA
input$avgwavefront[input$reordering == "none" | input$reordering == "Noack1" | input$reordering == "Noack2"] <- NA
input$RMSwavefront[input$reordering == "none" | input$reordering == "Noack1" | input$reordering == "Noack2"] <- NA

summary <- ddply(.parallel = TRUE, input, c(
				"type",
				"language",
				"filename",
				"graph",
				"reordering",
				"NES",
				"NWES",
				"bandwidth",
				"profile",
				"span",
				"avgwavefront",
				"RMSwavefront",
				"peaknodes"
				), summarize,
				
	# add summerized data
	
	## mean time
	mean_time = mean(time, na.rm = TRUE),
	mean_reachtime = mean(reachtime, na.rm = TRUE)
)

# split by performance and statistics
performance <- subset(summary, summary$type == "performance")
statistics <- subset(summary, summary$type == "statistics")

# keep useful columns
performance <- subset(performance, select = c(	"language", "filename", "graph", "reordering", 
												"mean_time", "mean_reachtime"))
statistics <- subset(statistics, select = c(	"language", "filename", "graph", "reordering", 
												"NES", "NWES", 
												"bandwidth", "profile", "span", "avgwavefront", "RMSwavefront",
												"peaknodes"))
								
								
# merge statistics and performance
summary <- merge(x=performance, y=statistics, by = c("language", "filename", "graph", "reordering"), all.y = TRUE)


# count for each file the number of unique reordering algorithms
completes <- ddply(.parallel = TRUE, summary, c("filename", "language"), summarise, count = length(NES))

# keep only those results that have at least one result for each reordering algorithm
# PNML has two more for noack
completes <- subset(completes, (completes$count == 14 & completes$language != "PNML") | (completes$language == "PNML" & completes$count == 16))
summary <- subset(summary, summary$filename %in% unique(completes$filename))

anon <- summary
# rename all languages to "all"
anon$language <- "all"

# append all new rows
summary <- rbind(summary, anon)

# backup original summary
mean_sd <- summary

# compute the mean and sd for all models
# this allows us to compute the mean standard score
mean_sd <- ddply(.parallel = TRUE, mean_sd, c("filename"),		
	function(x) c(					
		# NES
		mean_NES = mean(x$NES, na.rm = TRUE),
		sd_NES = sd(x$NES, na.rm = TRUE),
		
		# NWES
		mean_NWES = mean(x$NWES, na.rm = TRUE),
		sd_NWES = sd(x$NWES, na.rm = TRUE),
		
		# mean_time
		mean_mean_time = mean(x$mean_time, na.rm = TRUE),
		sd_mean_time = sd(x$mean_time, na.rm = TRUE),
		
		# mean_reachtime
		mean_mean_reachtime = mean(x$mean_reachtime, na.rm = TRUE),
		sd_mean_reachtime = sd(x$mean_reachtime, na.rm = TRUE),
		
		# peaknodes
		mean_peaknodes = mean(x$peaknodes, na.rm = TRUE),
		sd_peaknodes = sd(x$peaknodes, na.rm = TRUE)
	)
)

# backup original summary
mean_sd_graph <- summary

# compute the mean and sd for all models per graph
# this allows us to compute the mean standard score
mean_sd_graph <- ddply(.parallel = TRUE, mean_sd_graph, c("filename", "graph"),		
	function(x) c(
				
		# bandwidth
		mean_bandwidth = mean(x$bandwidth, na.rm = TRUE),
		sd_bandwidth = sd(x$bandwidth, na.rm = TRUE),
		
		# profile
		mean_profile = mean(x$profile, na.rm = TRUE),
		sd_profile = sd(x$profile, na.rm = TRUE),
		
		# span
		mean_span = mean(x$span, na.rm = TRUE),
		sd_span = sd(x$span, na.rm = TRUE),
		
		# avgwavefront
		mean_avgwavefront = mean(x$avgwavefront, na.rm = TRUE),
		sd_avgwavefront = sd(x$avgwavefront, na.rm = TRUE)
	)
)

# backup summary
score <- summary

# add the means and sds to reach file
score <- merge(score, mean_sd, by = c("filename"))

score <- merge(score, mean_sd_graph, by = c("filename", "graph"))

# merge graph and reordering
score <- within(score, reordering2 <- paste(reordering, graph, sep=","))
score$reordering2[score$reordering2 == "none,none"] <- "none"
score$reordering2[score$reordering2 == "Noack1,bipartite"] <- "Noack1"
score$reordering2[score$reordering2 == "Noack2,bipartite"] <- "Noack2"
score$reordering2[score$reordering2 == "FORCE,bipartite"] <- "FORCE"

languages <- unique(score$language)

g_legend<-function(a.gplot){
	tmp <- ggplot_gtable(ggplot_build(a.gplot))
	leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
	legend <- tmp$grobs[[leg]]
	legend
}

for (lan in languages) {
	
	plot_data <- subset(score, score$language == lan)
	if(lan == "all") {
		plot_data <- subset(plot_data, plot_data$reordering != "Noack1" & plot_data$reordering != "Noack2")
	} 
	
	N = length(unique(plot_data$filename))
	print(paste("Language", lan, "has", N, "models"))

	# now we compute the mean z-scores
	plot_data <- ddply(.parallel = TRUE, plot_data, c("reordering2", "reordering", "graph"),		
		function (x) c(
			score_time = sum(ifelse(x$sd_mean_time == 0, 0, (x$mean_time - x$mean_mean_time) / x$sd_mean_time)) / length(x$mean_time),
			score_NES = sum(ifelse(x$sd_NES == 0, 0, (x$NES - x$mean_NES) / x$sd_NES)) / length(x$NES),
			score_NWES = sum(ifelse(x$sd_NWES == 0, 0, (x$NWES - x$mean_NWES) / x$sd_NWES)) / length(x$NWES),
			score_bandwidth = sum(ifelse(x$sd_bandwidth == 0, 0, (x$bandwidth - x$mean_bandwidth) / x$sd_bandwidth)) / length(x$bandwidth),
			score_profile = sum(ifelse(x$sd_profile == 0, 0, (x$profile - x$mean_profile) / x$sd_profile)) / length(x$profile),
			score_span = sum(ifelse(x$sd_span == 0, 0, (x$span - x$mean_span) / x$sd_span)) / length(x$span),
			score_avgwavefront = sum(ifelse(x$sd_avgwavefront == 0, 0, (x$avgwavefront - x$mean_avgwavefront) / x$sd_avgwavefront)) / length(x$avgwavefront),
			score_reachtime = sum(ifelse(x$sd_mean_reachtime == 0, 0, (x$mean_reachtime - x$mean_mean_reachtime) / x$sd_mean_reachtime)) / length(x$mean_reachtime),
			score_peaknodes = sum(ifelse(x$sd_peaknodes == 0, 0, (x$peaknodes - x$mean_peaknodes) / x$sd_peaknodes)) / length(x$peaknodes)
		)
	)
	
	plot_data <- plot_data[with(plot_data, order(score_peaknodes)),]
	
	write.csv(plot_data, file=paste("plot_data-reach-", lan, ".csv", sep=""))
	
	b <- c("score_NWES", "score_reachtime", "score_peaknodes")
	l <- c("Weighted Event Span", "time", "peak nodes")
	
	
	pdf(paste("score-reach-", lan, ".pdf", sep = ""), height=2.5, width=6, title = paste("Mean Z - ", lan, sep=""))
	
	plot <- ggplot(plot_data,aes(x=reorder(reordering2, score_peaknodes, function(x) x))) +
			
			#ggtitle(paste("Mean Z score, ", lan, sep = "")) +
			
			geom_line(stat="identity", aes(y=score_NWES, group=3, linetype="score_NWES", color="score_NWES")) +
			geom_point(size=3,aes(y=score_NWES, shape="score_NWES", color="score_NWES")) +
			
			geom_line(stat="identity", aes(y=score_peaknodes, group=3, linetype="score_peaknodes", color="score_peaknodes")) +
			geom_point(size=3,aes(y=score_peaknodes, shape="score_peaknodes", color="score_peaknodes")) +
			
			geom_line(stat="identity", aes(y=score_reachtime, group=3, linetype="score_reachtime", color="score_reachtime")) +
			geom_point(size=3,aes(y=score_reachtime, shape="score_reachtime", color="score_reachtime")) +
			theme_bw() +
			theme(
					text = element_text(size=14), 
					axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),					
					axis.title.x=element_blank(),
					axis.title.y=element_blank())+	
			theme(legend.position=c(.50,.8), legend.title=element_blank(), legend.direction="horizontal") +
			scale_color_discrete(breaks=b, labels=l) +
			scale_shape_discrete(breaks=b, labels=l) +
			scale_linetype_discrete(breaks=b, labels=l) +
			theme(plot.margin = unit(c(0,0,0,0), "cm"))
	
	graph <- plot
	print(graph)
	dev.off()
	
}

warnings()
