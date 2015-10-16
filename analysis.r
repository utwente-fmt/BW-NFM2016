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
				"RMSwavefront"
				), summarize,
				
	# add summerized data
	
	## mean time
	mean_time = mean(time, na.rm = TRUE)
)

# split by performance and statistics
performance <- subset(summary, summary$type == "performance")
statistics <- subset(summary, summary$type == "statistics")

# keep useful columns
performance <- subset(performance, select = c(	"language", "filename", "graph", "reordering", 
												"mean_time"))
statistics <- subset(statistics, select = c(	"language", "filename", "graph", "reordering", 
												"NES", "NWES", 
												"bandwidth", "profile", "span", "avgwavefront", "RMSwavefront"))
								
								
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
		sd_mean_time = sd(x$mean_time, na.rm = TRUE)
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
			score_avgwavefront = sum(ifelse(x$sd_avgwavefront == 0, 0, (x$avgwavefront - x$mean_avgwavefront) / x$sd_avgwavefront)) / length(x$avgwavefront)
		)
	)
	
	plot_data <- plot_data[with(plot_data, order(score_NWES)),]
	
	write.csv(plot_data, file=paste("plot_data-", lan, ".csv", sep=""))
	
	b <- c("score_NWES", "score_NES", "score_bandwidth", "score_profile", "score_avgwavefront", "score_time")
	l <- c("Weighted Event Span", "Event Span", "bandwidth", "profile", "average wavefront", "time")
	
	
	pdf(paste("score-", lan, ".pdf", sep = ""), height=3, width=5, title = paste("Mean Z - ", lan, sep=""))
	
	plot <- ggplot(plot_data,aes(x=reorder(reordering2, score_NWES, function(x) x))) +
			
			#ggtitle(paste("Mean Z score, ", lan, sep = "")) +
			
			geom_line(stat="identity", aes(y=score_NWES, group=3, linetype="score_NWES", color="score_NWES")) +
			geom_point(size=3,aes(y=score_NWES, shape="score_NWES", color="score_NWES")) +
			
			geom_line(stat="identity", aes(y=score_NES, group=3, linetype="score_NES", color="score_NES")) +
			geom_point(size=3,aes(y=score_NES, shape="score_NES", color="score_NES")) +
			
			geom_line(stat="identity", aes(y=score_bandwidth, group=3, linetype="score_bandwidth", color="score_bandwidth")) +
			geom_point(size=3,aes(y=score_bandwidth, shape="score_bandwidth", color="score_bandwidth")) +
			
			geom_line(stat="identity", aes(y=score_profile, group=3, linetype="score_profile", color="score_profile")) +
			geom_point(size=3,aes(y=score_profile, shape="score_profile", color="score_profile")) +
			
			geom_line(stat="identity", aes(y=score_avgwavefront, group=3, linetype="score_avgwavefront", color="score_avgwavefront")) +
			geom_point(size=3,aes(y=score_avgwavefront, shape="score_avgwavefront", color="score_avgwavefront")) +
			
			geom_line(stat="identity", aes(y=score_time, group=3, linetype="score_time", color="score_time")) +
			geom_point(size=3,aes(y=score_time, shape="score_time", color="score_time")) +
			theme_bw() +
			theme(
					text = element_text(size=14), 
					axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),					
					axis.title.x=element_blank(),
					axis.title.y=element_blank(),
					legend.position="none") +
			scale_color_discrete(breaks=b, labels=l) +
			scale_shape_discrete(breaks=b, labels=l) +
			scale_linetype_discrete(breaks=b, labels=l) +
			theme(plot.margin = unit(c(0,0,0,0), "cm"))
	
	graph <- plot + guides(colour=FALSE, linetype=FALSE, size=FALSE)
	print(graph)
	dev.off()
			
	pdf("score-legend.pdf", width=7.3, height=.4, title="Score Legend", onefile=FALSE)
	legend <- plot + theme(legend.position=c(.5,.5), legend.title=element_blank(), legend.direction="horizontal", legend.text=element_text(size=12))
	legend <- g_legend(legend)					
	grid.arrange(legend)
	dev.off()
		
	scatter_none <- subset(summary, 
			summary$reordering == "none" & summary$language == lan, 
			select = c("filename", "NWES"))
		
	scatter_best <- subset(summary, 
			summary$reordering == "Sloan" & summary$graph == "total" & summary$language == lan,
			select = c("filename", "NWES"))
	
	scatter <- merge(scatter_none, scatter_best, by = c("filename"))
	
	b = c(.01,.1,.2,.5,.8,1,2);
	l = c(.01,.1,.2,.5,.8,1,2);
	
	best_wins = with(scatter, c(best = sum(scatter$NWES.y <= scatter$NWES.x), none = sum(scatter$NWES.y > scatter$NWES.x)))
		
	ggplot(scatter, aes(x=NWES.x, y=NWES.y)) +
			scale_x_continuous(paste("None:", best_wins["none"])
			) +
			scale_y_continuous(paste("Sloan,total:", best_wins["best"])
			) +
			theme_bw() +
			theme(text = element_text(size=24)) +
			
			geom_abline(slope=1, intercept=0, linetype="dotted") +
			geom_point(shape=19)
	
	ggsave(file = paste("scatter-", lan, "-", "Sloan,total", ".pdf", sep=""),
			title = paste("scatter - ", lan, " - ", "Sloan,total", sep=""))
	
	time <- summary
	time$mean_time[time$mean_time == 0] <- .001
	
	scatter_bi <- subset(time, 
			time$reordering == "Sloan" & time$graph == "bipartite" & time$language == lan, 
			select = c("filename", "mean_time"))
	
	scatter_tot <- subset(time, 
			time$reordering == "Sloan" & time$graph == "total" & time$language == lan,
			select = c("filename", "mean_time"))
	
	scatter <- merge(scatter_bi, scatter_tot, by = c("filename"))
			
	b = c(.001,3600);
	l = c(.001,3600);
	limits = c(.001,3600);
	
	ggplot(scatter, aes(x=mean_time.x, y=mean_time.y)) +
			scale_x_log10("Bipartite",limits=limits
			) +
			scale_y_log10("Total", limits=limits
			) +
			theme_bw() +
			theme(text = element_text(size=24)) +
			
			geom_abline(slope=1, intercept=0, linetype="dotted") +
			geom_point(shape=19)
	
	ggsave(file = paste("scatter-", lan, "-", "Sloan bipartite vs total", ".pdf", sep=""),
			title = paste("scatter - ", lan, " - ", "Sloan bipartite vs total", sep=""))
	
}

warnings()
