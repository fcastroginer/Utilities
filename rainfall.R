# Intermutation distance
im.distance <- function(Chromosome, Position) {
  x <- data.frame(cbind(Chromosome, Position), stringsAsFactors = F)
  x$Position <- as.numeric(x$Position)
  x$Order <- 1:nrow(x)
  x <- x[order(x$Position),]
  x$imd <- NA
  for (chr in levels(factor(Chromosome))) {
    y <- x[x$Chromosome==chr,]
    p1 <- c(y$Position, 9999999999)
    p2 <- c(0, y$Position)
    imd <- p1 - p2
    imd <- imd[-length(imd)]
    x[x$Chromosome==chr,"imd"] <- imd
  }
  x <- x[order(x$Order),]
  x$Order <- NULL
  return(x)
}


# Rainfall Plot
rainfall.plot <- function(Chromosome, Position, IMD, Group) {
  data <- cbind(Chromosome, Position, IMD)
  data <- data.frame(data, stringsAsFactors = F)
  
  data$Position <- as.numeric(data$Position)
  data$IMD <- as.numeric(data$IMD)
  
  if(exists("Group")) data <- cbind(data, Group)
  
  # Check default parameters
  if(!exists("bin")) bin <- 100000
  if(!exists("BSgenome_Name")) BSgenome_Name <- "BSgenome.Hsapiens.UCSC.hg19"
  if(!exists("main")) main <- ""
  
  
  # Loading Libraries
  suppressPackageStartupMessages(library(GenomicRanges))
  suppressPackageStartupMessages(library(BSgenome_Name, character.only = T))
  suppressPackageStartupMessages(library(ggplot2))
  suppressPackageStartupMessages(library(ggbio))
  suppressPackageStartupMessages(library(gridExtra))
  suppressPackageStartupMessages(library(plyr))
  
  
  # Arguments format
  bin <- as.numeric(bin)
  
  
  # Get Chromosomes lengths
  chrlengths <- seqlengths(get(BSgenome_Name))
  names(chrlengths) <- gsub("chr", "", names(chrlengths))
  chrNumeric <- grep("^[0-9]+$", names(chrlengths), value = T) # Get only numeric chr
  chrNonNumeric <- grep("^[0-9]+$", names(chrlengths), value = T, invert = T)
  chrNonNumeric <- chrNonNumeric[chrNonNumeric %in% data$Chromosome]
  chrLevels <- c(chrNumeric, chrNonNumeric)
  chrlengths <- chrlengths[chrLevels]
  
  # Convert coordinates by bin size
  data$Position_bin <- ceiling(as.integer(data$Position)/bin)
  chrlengths <- ceiling(chrlengths/bin)
  
  
  # Creating positions matrix
  if(exists("posM")){ rm(posM)}
  for (chr in names(chrlengths)) {
    for (i in 1:chrlengths[chr]){
      if(exists("posM")) {
        posM <- rbind(posM, c(chr,i))
      } else {
        posM <- c(chr,i)
      }
    }  
  }
  
  row.names(posM) <- NULL
  posM <- data.frame(posM)
  names(posM) <- c("chr","bin")
  posM$id <- paste(posM$chr,posM$bin, sep="_")
  posM$pos <- 1:dim(posM)[1]
  posM <- posM[,c("id","pos")]
  
  
  # Add position to Data
  data$PosBin <- paste(data$Chromosome, data$Position_bin, sep="_")
  data <- merge(data, posM, by.x="PosBin", by.y="id")
  
  
  
  # Plot
  sl <- chrlengths
  csl <- cumsum(chrlengths)
  breaks <- csl - (sl/2)
  xlim <- c(1, max(posM$pos))
  
  p <- ggplot(data, aes(x=pos, y=IMD, color=factor(Group))) 
  if(exists("Group")) p <- ggplot(data, aes(x=pos, y=IMD, color=factor(Group))) 
  
  p <- p +
    geom_point(shape=19) +
    scale_x_continuous(name = "Chromosome", 
                       breaks=breaks,
                       minor_breaks = csl[-length(csl)]+0.5, 
                       limits=xlim, expand=c(0,0)) +
    theme(panel.background=element_blank()) +
    theme(panel.grid.major.x=element_blank(), panel.grid.minor.x=element_blank()) +
    theme(panel.grid.minor.x=element_line(colour='red',linetype='dashed')) +
    scale_y_log10(name = "log10(Intermutation Distance)")
  
  p


}


