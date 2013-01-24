#' Plot model diagnostics in a grid, with inputs.
#' 
#' @import ggplot2 grid
#' @param model A model object, can be from lm() or glm() call I think. 
#' @param data The data that was used in the model.
#' @param tplot Plot points or text labels.
#' @param which Which plots to print out.
#' @param mfrow Number of rows and columns of output.
#' @param ... Passed on to somewhere...
#' @details
#' 		Modified from \link{http://librestats.com/2012/06/11/autoplot-graphical-methods-with-ggplot2/}
#' @examples
#' library(ggplot2)
#' data(mtcars)
#' mod <- lm(mpg ~ qsec, data=mtcars)
#' ggmoddiag(mod, which=1:6, mfrow=c(3,2))
#' @export
ggmoddiag <- function(model, toplot="points", which=c(1:3, 5), mfrow=c(1,1), ...)
{
	df <- fortify(model)
	df <- cbind(df, rows=1:nrow(df))
	
	if(toplot == "points"){
		toplot <- geom_point()
	} else if(toplot == "labels")
		{ toplot <- geom_text(aes(label=rows)) }
	
	# residuals vs fitted
	g1 <- ggplot(df, aes(.fitted, .resid)) +
		toplot +
		geom_smooth(se=FALSE, method="loess") +
		geom_hline(linetype=2, size=.2, aes(yintercept=0)) +
		scale_x_continuous("Fitted Values") +
		scale_y_continuous("Residual") +
		ggtitle("Residuals vs Fitted")
	
	# normal qq	
	a <- quantile(df$.stdresid, c(0.25, 0.75))
	b <- qnorm(c(0.25, 0.75))
	slope <- diff(a)/diff(b)
	int <- a[1] - slope * b[1]
	g2 <- ggplot(df, aes(sample=.resid)) +
		stat_qq() +
		geom_abline(slope=slope, intercept=int) +
		scale_x_continuous("Theoretical Quantiles") +
		scale_y_continuous("Standardized Residuals") +
		ggtitle("Normal Q-Q")
	
# 	y <- quantile(df$.stdresid[!is.na(df$.stdresid)], c(0.25, 0.75))
# 	x <- qnorm(c(0.25, 0.75))
# 	slope <- diff(y)/diff(x)
# 	int <- y[1L] - slope * x[1L]
# 	g2 <- ggplot(df, aes(sample=.resid)) +
# 		theme_bw(base_size=18) +
# 		geom_point(stat = "qq", size=5) +
# 		geom_abline(slope = slope, intercept = int, color="blue")	+
# 		ggtitle("Normal Q-Q")
	
# 	# scale-location
# 	g3 <- ggplot(df, aes(.fitted, sqrt(abs(.stdresid)))) +
# 		toplot +
# 		geom_smooth(se=FALSE, method="loess") +
# 		scale_x_continuous("Fitted Values") +
# 		scale_y_continuous("Root of Standardized Residuals") +
# 		ggtitle("Scale-Location")
	
	# histogram of residuals
	g3 <- ggplot(df, aes(.resid)) +
		geom_density() +
		scale_y_continuous("Residuals") +
		ggtitle("Residuals Histogram")
	
	# cook's distance
	g4 <-  ggplot(df, aes(rows, .cooksd, ymin=0, ymax=.cooksd)) +
		toplot + 
		geom_linerange() +
		scale_x_continuous("Observation Number") +
		scale_y_continuous("Cook's distance") +
		ggtitle("Cook's Distance")
	
	# residuals vs leverage
	g5 <- ggplot(df, aes(.hat, .stdresid)) +
		toplot +
		geom_smooth(se=FALSE, method="loess") +
		geom_hline(linetype=2, size=.2) +
		scale_x_continuous("Leverage") +
		scale_y_continuous("Standardized Residuals") +
		ggtitle("Residuals vs Leverage")
		
	# cooksd vs leverage
	g6 <- ggplot(df, aes(.hat, .cooksd)) +
		toplot +
		geom_smooth(se=FALSE, method="loess") +
		scale_x_continuous("Leverage") +
		scale_y_continuous("Cook's distance") +
		ggtitle("Cook's dist vs Leverage")
	
	plots <- list(g1, g2, g3, g4, g5, g6)
	
	# making the plots
	grid.newpage()
	
	if (prod(mfrow)>1) {
		mypos <- expand.grid(1:mfrow[1], 1:mfrow[2])
		mypos <- mypos[with(mypos, order(Var1)), ]
		pushViewport(viewport(layout = grid.layout(mfrow[1], mfrow[2])))
		formatter <- function(.){}
	} else {
		mypos <- data.frame(matrix(1, length(which), 2))
		pushViewport(viewport(layout = grid.layout(1, 1)))
		formatter <- function(.) {
			.dontcare <- readline("Hit <Return> to see next plot: ")
			grid.newpage()
		}
	}
	
	j <- 1
	for (i in which){
		formatter()
		print(plots[[i]], vp=viewport(layout.pos.row=mypos[j,][1], layout.pos.col=mypos[j,][2]))
		j <- j+1
	}
}