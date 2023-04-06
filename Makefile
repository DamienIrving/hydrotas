.PHONY: help

include ${MODEL_CONFIG}
#Model config file needs to define MODEL, MODEL_IO_OPTIONS (optional) MIN_LEAD,
#BASE_PERIOD, BASE_PERIOD_TEXT and TIME_PERIOD_TEXT


PROJECT_DIR=/g/data/xv83/dbi599/hydrotas
VAR=pr
DASK_CONFIG=dask_local.yml
SHAPEFILE=/home/599/dbi599/hydrotas/shapefiles/hydro-combined.shp
REGION_NAME=hydro-tas

RX14DAY_OPTIONS_FCST=--lat_bnds -47 -37 --lon_bnds 141 152 --shp_overlap 0.05 --output_chunks lead_time=50
RX14DAY_OPTIONS=--variables ${VAR} --spatial_agg weighted_mean --rolling_sum_window 14 --shapefile ${SHAPEFILE} --time_freq A-DEC --time_agg max --input_freq D --units_timing middle --reset_times --complete_time_agg_periods --dask_config ${DASK_CONFIG} --verbose --time_agg_dates --units pr='mm day-1'
OBS_CONFIG=/home/599/dbi599/unseen/config/dataset_agcd_daily.yml
RX14DAY_OBS=${PROJECT_DIR}/data/Rx14day_AGCD-CSIRO_r005_1900-2022_annual_${REGION_NAME}.zarr.zip
SST_OBS=/g/data/ia39/aus-ref-clim-data-nci/hadisst/data/HadISST_sst.nc
NINO_FCST=${PROJECT_DIR}/data/nino34-anomaly_${MODEL}-${EXPERIMENT}_${TIME_PERIOD_TEXT}_base-${BASE_PERIOD_TEXT}.nc
NINO_OBS=${PROJECT_DIR}/data/nino34-anomaly_HadISST_1870-2022_base-1981-2010.nc
FCST_DATA=/home/599/dbi599/hydrotas/file_lists/${MODEL}_${EXPERIMENT}_pr_files.txt
FCST_TOS_DATA=/home/599/dbi599/hydrotas/file_lists/${MODEL}_${EXPERIMENT}_tos_files.txt
OBS_DATA := $(sort $(wildcard /g/data/xv83/agcd-csiro/precip/daily/precip-total_AGCD-CSIRO_r005_*_daily.nc))
RX14DAY_FCST=${PROJECT_DIR}/data/Rx14day_${MODEL}-${EXPERIMENT}_${TIME_PERIOD_TEXT}_annual_${REGION_NAME}.zarr.zip
INDEPENDENCE_PLOT=${PROJECT_DIR}/figures/independence-test_Rx14day_${MODEL}-${EXPERIMENT}_${TIME_PERIOD_TEXT}_annual_${REGION_NAME}.png
RX14DAY_FCST_ADDITIVE_BIAS_CORRECTED=${PROJECT_DIR}/data/Rx14day_${MODEL}-${EXPERIMENT}_${TIME_PERIOD_TEXT}_annual_${REGION_NAME}_bias-corrected-AGCD-CSIRO-additive.zarr.zip
RX14DAY_FCST_MULTIPLICATIVE_BIAS_CORRECTED=${PROJECT_DIR}/data/Rx14day_${MODEL}-${EXPERIMENT}_${TIME_PERIOD_TEXT}_annual_${REGION_NAME}_bias-corrected-AGCD-CSIRO-multiplicative.zarr.zip
SIMILARITY_ADDITIVE_BIAS=${PROJECT_DIR}/data/similarity-test_Rx14day_${MODEL}-${EXPERIMENT}_${BASE_PERIOD_TEXT}_annual_${REGION_NAME}_bias-corrected-AGCD-CSIRO-additive.zarr.zip
SIMILARITY_MULTIPLICATIVE_BIAS=${PROJECT_DIR}/data/similarity-test_Rx14day_${MODEL}-${EXPERIMENT}_${BASE_PERIOD_TEXT}_annual_${REGION_NAME}_bias-corrected-AGCD-CSIRO-multiplicative.zarr.zip
SIMILARITY_RAW=${PROJECT_DIR}/data/similarity-test_Rx14day_${MODEL}-${EXPERIMENT}_${BASE_PERIOD_TEXT}_annual_${REGION_NAME}_AGCD-CSIRO.zarr.zip

FILEIO=/g/data/xv83/dbi599/miniconda3/envs/unseen-processing/bin/fileio
PAPERMILL=/g/data/xv83/dbi599/miniconda3/envs/unseen2/bin/papermill
INDEPENDENCE=/g/data/xv83/dbi599/miniconda3/envs/unseen-processing/bin/independence
BIAS_CORRECTION=/g/data/xv83/dbi599/miniconda3/envs/unseen-processing/bin/bias_correction
SIMILARITY=/g/data/xv83/dbi599/miniconda3/envs/unseen-processing/bin/similarity


## rx14day-obs : calculate Rx14day in observations
rx14day-obs : ${RX14DAY_OBS}
${RX14DAY_OBS} :
	${FILEIO} ${OBS_DATA} $@ ${RX14DAY_OPTIONS} --metadata_file /home/599/dbi599/unseen/config/dataset_agcd_daily.yml

## nino34-obs : calculate Nino 3.4 in observations
nino34-obs : ${NINO_OBS}
${NINO_OBS} :
	${FILEIO} ${SST_OBS} $@ --variables sst --spatial_agg mean --lat_bnds -5 5 --lon_bnds -170 -120 --lat_dim latitude --lon_dim longitude --anomaly 1980-01-01 2009-12-31 --anomaly_freq month --verbose

## rx14day-obs-analysis : analyse Rx14day in observations
rx14day-obs-analysis : AGCD_${REGION_NAME}.ipynb
AGCD_${REGION_NAME}.ipynb : AGCD.ipynb ${RX14DAY_OBS} ${NINO_OBS}
	${PAPERMILL} -p rx14day_file $(word 2,$^) -p region_name ${REGION_NAME} -p nino_file $(word 3,$^) $< $@	

## rx14day-forecast : calculate Rx14day in forecast ensemble
rx14day-forecast : ${RX14DAY_FCST}
${RX14DAY_FCST} : ${FCST_DATA}
	${FILEIO} $< $@ --forecast ${RX14DAY_OPTIONS} ${RX14DAY_OPTIONS_FCST} ${MODEL_IO_OPTIONS}

## independence-test : independence test for different lead times
independence-test : ${INDEPENDENCE_PLOT}
${INDEPENDENCE_PLOT} : ${RX14DAY_FCST}
	${INDEPENDENCE} $< ${VAR} $@

## bias-correction-additive : additive bias corrected forecast data using observations
bias-correction-additive : ${RX14DAY_FCST_ADDITIVE_BIAS_CORRECTED}
${RX14DAY_FCST_ADDITIVE_BIAS_CORRECTED} : ${RX14DAY_FCST} ${RX14DAY_OBS}
	${BIAS_CORRECTION} $< $(word 2,$^) ${VAR} additive $@ --base_period ${BASE_PERIOD} --rounding_freq A --min_lead ${MIN_LEAD}

## bias-correction-multiplicative : multiplicative bias corrected forecast data using observations
bias-correction-multiplicative : ${RX14DAY_FCST_MULTIPLICATIVE_BIAS_CORRECTED}
${RX14DAY_FCST_MULTIPLICATIVE_BIAS_CORRECTED} : ${RX14DAY_FCST} ${RX14DAY_OBS}
	${BIAS_CORRECTION} $< $(word 2,$^) ${VAR} multiplicative $@ --base_period ${BASE_PERIOD} --rounding_freq A --min_lead ${MIN_LEAD}

## similarity-test-additive-bias : similarity test between observations and additive bias corrected forecast
similarity-test-additive-bias : ${SIMILARITY_ADDITIVE_BIAS}
${SIMILARITY_ADDITIVE_BIAS} : ${RX14DAY_FCST_ADDITIVE_BIAS_CORRECTED} ${RX14DAY_OBS}
	${SIMILARITY} $< $(word 2,$^) ${VAR} $@ --reference_time_period ${BASE_PERIOD}

## similarity-test-multiplicative-bias : similarity test between observations and multiplicative bias corrected forecast
similarity-test-multiplicative-bias : ${SIMILARITY_MULTIPLICATIVE_BIAS}
${SIMILARITY_MULTIPLICATIVE_BIAS} : ${RX14DAY_FCST_MULTIPLICATIVE_BIAS_CORRECTED} ${RX14DAY_OBS}
	${SIMILARITY} $< $(word 2,$^) ${VAR} $@ --reference_time_period ${BASE_PERIOD}

## similarity-test-raw : similarity test between observations and raw forecast
similarity-test-raw : ${SIMILARITY_RAW}
${SIMILARITY_RAW} : ${RX14DAY_FCST} ${RX14DAY_OBS}
	${SIMILARITY} $< $(word 2,$^) ${VAR} $@ --reference_time_period ${BASE_PERIOD}

## nino34-forecast : calculate Nino 3.4 in forecast ensemble
nino34-forecast : ${NINO_FCST}
${NINO_FCST} : ${FCST_TOS_DATA}
	${FILEIO} $< $@ --forecast --variables tos --spatial_agg mean --lat_bnds -5 5 --verbose ${MODEL_NINO_OPTIONS} 

## rx14day-forecast-analysis : analysis of rx14day from forecast data
rx14day-forecast-analysis : analysis_${MODEL}.ipynb
analysis_${MODEL}.ipynb : analysis.ipynb ${RX14DAY_OBS} ${RX14DAY_FCST} ${RX14DAY_FCST_ADDITIVE_BIAS_CORRECTED} ${RX14DAY_FCST_MULTIPLICATIVE_BIAS_CORRECTED} ${SIMILARITY_ADDITIVE_BIAS} ${SIMILARITY_MULTIPLICATIVE_BIAS} ${SIMILARITY_RAW} ${INDEPENDENCE_PLOT} ${FCST_DATA} ${NINO_FCST}
	${PAPERMILL} -p agcd_file $(word 2,$^) -p model_file $(word 3,$^) -p model_add_bc_file $(word 4,$^) -p model_mulc_bc_file $(word 5,$^) -p similarity_add_bc_file $(word 6,$^) -p similarity_mulc_bc_file $(word 7,$^) -p similarity_raw_file $(word 8,$^) -p independence_plot $(word 9,$^) -p model_name ${MODEL} -p min_lead ${MIN_LEAD} -p region_name ${REGION_NAME} -p shape_file ${SHAPEFILE} -p file_list $(word 10,$^) -p nino_file $(word 11,$^) $< $@

## help : show this message
help :
	@echo 'make [target] [-Bnf] MODEL_CONFIG=config_file.mk'
	@echo ''
	@echo 'valid targets:'
	@grep -h -E '^##' ${MAKEFILE_LIST} | sed -e 's/## //g' | column -t -s ':'
