library(raster) # https://cran.r-project.org/web/packages/raster/raster.pdf
library(fs)
library(rgdal)

population_path <- fs::path("data",
  "large",
  "population",
  "gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-2020",
  "gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals_2020.tif"
)

population_data <- raster(population_path)

### Step 1: decrease resolution
# We will aggregate from cells of 1/120 * 1/120 degrees to 50 * 50km squares.
# To do this, we will need to multiply the cells by a factor.
current_cell_res <- res(population_data)[1] # 1/120 degrees (slightly less than 1km)

km_per_degree <- 111.139 # https://sciencing.com/convert-distances-degrees-meters-7858322.html
degrees_50_km <- 50 / km_per_degree
factor <- degrees_50_km / current_cell_res

# This gives us a factor very close to 54 (53.98).
# We will round it to 54 because we need an integer value.
# So, the cells won't be exactly 50*50km but very close.
factor <- round(factor)

population_data_agg <- aggregate(population_data, fact = factor, fun = sum)

### Step 2: classification
# We will take 100 people per square kilometer as the minimum value
# Areas with less than this will be not be classified as populated
min_people_sq_km <- 100
plusmin_50_km <- current_cell_res * km_per_degree * factor
min_people_plusminus_50_sq_km <- min_people_sq_km * (plusmin_50_km ** 2)

bottom_treshold <- min_people_plusminus_50_sq_km

# TODO more classes
classification <- c(
  -Inf, bottom_treshold, 0,
  bottom_treshold, Inf, 1
)

population_data_classified <- reclassify(population_data_agg, classification)

### Step 3: convert to polygon
polygons <- rasterToPolygons(population_data_classified, fun = function(x) { x > 0}, dissolve = TRUE)

### Step 4: write to file
output_path <- fs::path("output", "population2020", "population-centers.geojson")
writeOGR(polygons, output_path, layer = "over100", driver = "GeoJSON")
