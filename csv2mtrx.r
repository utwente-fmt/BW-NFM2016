#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(cowplot)
library(tools)
args <- commandArgs(trailingOnly = TRUE)

f <- file("stdin")
open(f)
lines <- readLines(f)
input <- read.delim(textConnection(lines),header=TRUE,sep=",")

xbreaks <- round(seq(0, max(input$x), by=max(input$x)/10))
xbreaks[1] = 1
ybreaks <- round(seq(0, max(input$y), by=max(input$y)/10))
ybreaks[1] = 1

sp <- ggplot(input, aes(x=x, y=y)) +
		geom_point(size=1) +
#		theme(axis.line=element_blank(),
#          axis.text.x=element_blank(),
#          axis.text.y=element_blank(),
#          axis.ticks=element_blank(),
#          axis.title.x=element_blank(),
#          axis.title.y=element_blank(),
#          legend.position="none") +
		ggtitle(basename(args[1])) +
		scale_colour_brewer(palette="Set1") +
		scale_x_continuous(name="variables", breaks=xbreaks) +
		scale_y_reverse(name="transitions", breaks=ybreaks)
sp <- ggdraw(switch_axis_position(sp, 'x'))


# the name of the file to write to
name = sprintf("%s.pdf", args[1])

r <- ifelse(max(input$x)/max(input$y) > max(input$y)/max(input$x), max(input$x)/max(input$y), max(input$y)/max(input$x))

# create a pdf.
if(max(input$x)/max(input$y) > max(input$y)/max(input$x)) {
	pdf(name, 10, max(input$y)/max(input$x)*10)
} else {
	pdf(name, max(input$x)/max(input$y)*10, 10)
}
print(sp)
graphics.off()
