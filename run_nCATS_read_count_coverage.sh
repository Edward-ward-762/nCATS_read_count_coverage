##UPDATE PIPELINE
nextflow pull Edward-ward-762/nCATS_read_count_coverage -r main

##RUN PIPELINE
nextflow run Edward-ward-762/nCATS_read_count_coverage \
-r main \
-profile docker \
-resume \
--input_file ./inputFile.csv 
