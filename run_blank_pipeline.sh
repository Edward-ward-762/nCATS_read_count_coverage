##UPDATE PIPELINE
nextflow pull Edward-ward-762/blank_pipeline -r main

##RUN PIPELINE
nextflow run Edward-ward-762/blank_pipeline \
-r main \
-profile docker \
-resume \
--inputFile ./inputFile.csv 
