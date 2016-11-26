library(h2o)

#Initialise h2o cluster
h2o.init(nthreads = -1, max_mem_size="5g")
h2o.removeAll()

#Load frames
myPath <- "../input/town_state.csv"
towns.hex <- h2o.importFile(path = myPath, destination_frame = "towns.hex")

myPath <- "../input/cliente_tabla.csv"
client.hex <- h2o.importFile(path = myPath, destination_frame = "client.hex")

myPath <- "../input/producto_tabla.csv"
product.hex <- h2o.importFile(path = myPath, destination_frame = "product.hex")

myPath <- "../input/train.csv"
train.hex <- h2o.importFile(path = myPath, destination_frame = "train.hex")

myPath <- "../input/test.csv"
test.hex <- h2o.importFile(path = myPath, destination_frame = "test.hex")

rm(myPath)


#Calculate weekly variables

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


#Generate submission file
predict.km <- h2o.predict(fit.km, newdata = ntest.hex)

submission.df <- 
  
names(submission.df) <- c("id", "Demanda_uni_equil")