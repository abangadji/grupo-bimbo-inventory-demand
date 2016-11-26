rm(list = ls())

library(h2o)

h2o.init(nthreads = -1, max_mem_size="5g")


###############################################################################
## Load data directly zipped, let h2o do the magic

myPath <- "./data/town_state.csv.zip"
towns.hex <- h2o.importFolder(path = myPath, destination_frame = "towns.hex")

myPath <- "./data/cliente_tabla.csv.zip"
client.hex <- h2o.importFolder(path = myPath, destination_frame = "client.hex")

myPath <- "./data/producto_tabla.csv.zip"
product.hex <- h2o.importFolder(path = myPath, destination_frame = "product.hex")

myPath <- "./data/train.csv.zip"
train.hex <- h2o.importFolder(path = myPath, destination_frame = "train.hex")

myPath <- "./data/test.csv.zip"
test.hex <- h2o.importFolder(path = myPath, destination_frame = "test.hex")

rm(myPath)


###############################################################################
## Calculate weekly variables

sales.hex <- h2o.group_by(data = train.hex,
                           by = c("Semana", "Cliente_ID", "Producto_ID"),
                           sum("Venta_uni_hoy"),
                           gb.control = list(na.methods="rm"))
returns.hex <- h2o.group_by(data = train.hex,
                            by = c("Semana", "Cliente_ID", "Producto_ID"),
                            sum("Dev_uni_proxima"),
                            gb.control = list(na.methods="rm"))

ntrain.hex < h2o.merge(x = train.hex, y = towns.hex, all.x = TRUE)
ntest.hex < h2o.merge(x = test.hex, y = towns.hex, all.x = TRUE)


#Estimate clusters and calculate average per cluster
fit.km <- h2o.kmeans(training_frame = ntrain.hex, seed = 123, k = 1000,
                     x = c("Producto_ID", "Town"))

salesXcluster <- h2o.group_by(data = sales.hex,
                              by = fit.km@model$cluster,
                              mean("Venta_uni_hoy"),
                              gb.control = list(na.methods="rm"))

retXcluster <- h2o.group_by(data = returns.hex,
                            by = fit.km@model$cluster,
                            mean("Dev_uni_proxima"),
                            gb.control = list(na.methods="rm"))

adjsales <- salesXcluster - retXcluster

###############################################################################
## EDA

str(client.hex)
str(product.hex)
str(towns.hex)
str(train.hex)
str(test.hex)

summary(train.hex)


###############################################################################
## Cluster products based on name



###############################################################################
## Prediction

depvar <- "Demanda_uni_equil"
indepvar <- c("")

## Random forest
rf <- h2o.randomForest(x = indepvar, y = depvar, training_frame = train.hex)

###############################################################################
## Generate submission file

names(submission.df) <- c("id", "Demanda_uni_equil")