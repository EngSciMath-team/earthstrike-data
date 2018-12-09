all: population

population:
	# see http://sedac.ciesin.columbia.edu/data/collection/gpw-v4
	mkdir -p ./data/population; \
	wget -O ./data/population/pop2020.zip #TODO: url ; \
	unzip ./data/population/pop2020.zip; \
	rm ./data/population/pop2020.zip;
