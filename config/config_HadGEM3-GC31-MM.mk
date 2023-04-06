
MODEL=HadGEM3-GC31-MM
EXPERIMENT=dcppA-hindcast
MODEL_IO_OPTIONS=--n_ensemble_files 10 --n_time_files 12
MIN_LEAD=0
BASE_PERIOD=1970-01-01 2018-12-20
BASE_PERIOD_TEXT=197011-201811
TIME_PERIOD_TEXT=196011-201811
MODEL_NINO_OPTIONS=${MODEL_IO_OPTIONS} --lon_bnds -170 -120 --lat_dim latitude --lon_dim longitude --agg_y_dim j --agg_x_dim i --anomaly ${BASE_PERIOD} --anomaly_freq month


