if [ -z $INSTALL_DIR ]; then
	echo "Please source setup-env.sh in the root directory of this project"
	echo "before sourcing this file."
else
	export SCOREP_ENABLE_PROFILING=false
	export SCOREP_ENABLE_TRACING=true
	export SCOREP_ENABLE_UNWINDING=false
	export SCOREP_VERBOSE=true
	export SCOREP_TOTAL_MEMORY=10M
	export SCOREP_PAGE_SIZE=8K
	export SCOREP_EXPERIMENT_DIRECTORY='experiments/scorep-experiment'
	export SCOREP_OVERWRITE_EXPERIMENT_DIRECTORY=true
	export SCOREP_MACHINE_NAME='Linux'
	export SCOREP_EXECUTABLE=''
	export SCOREP_FORCE_CFG_FILES=true
	export SCOREP_TIMER='tsc'
	export SCOREP_PROFILING_TASK_EXCHANGE_NUM=1K
	export SCOREP_PROFILING_MAX_CALLPATH_DEPTH=100
	export SCOREP_PROFILING_BASE_NAME='profile'
	export SCOREP_PROFILING_FORMAT='cube4'
	export SCOREP_PROFILING_ENABLE_CLUSTERING=true
	export SCOREP_PROFILING_CLUSTER_COUNT=64
	export SCOREP_PROFILING_CLUSTERING_MODE='subtree'
	export SCOREP_PROFILING_CLUSTERED_REGION=''
	export SCOREP_PROFILING_ENABLE_CORE_FILES=false
	export SCOREP_TRACING_USE_SION=false
	export SCOREP_TRACING_MAX_PROCS_PER_SION_FILE=1K
	export SCOREP_TRACING_CONVERT_CALLING_CONTEXT_EVENTS=false
	export SCOREP_FILTERING_FILE=''
	export SCOREP_SUBSTRATE_PLUGINS=''
	export SCOREP_SUBSTRATE_PLUGINS_SEP=','
	export SCOREP_LIBWRAP_PATH=''
	export SCOREP_LIBWRAP_ENABLE=''
	export SCOREP_LIBWRAP_ENABLE_SEP=','
	export SCOREP_METRIC_RUSAGE=''
	export SCOREP_METRIC_RUSAGE_PER_PROCESS=''
	export SCOREP_METRIC_RUSAGE_SEP=','
	export SCOREP_METRIC_PLUGINS='coretemp_plugin'
	export SCOREP_METRIC_PLUGINS_SEP=','
	export SCOREP_METRIC_PERF=''
	export SCOREP_METRIC_PERF_PER_PROCESS=''
	export SCOREP_METRIC_PERF_SEP=','
	export SCOREP_METRIC_CORETEMP_PLUGIN='coretemp:::hwmon2:power1_input,coretemp:::hwmon3:power1_input,coretemp:::hwmon4:power1_input,coretemp:::hwmon5:power1_input'
	export SCOREP_SAMPLING_EVENTS='perf_cycles@10000000'
	export SCOREP_SAMPLING_SEP=','
	export SCOREP_TOPOLOGY_PLATFORM=true
	export SCOREP_TOPOLOGY_PROCESS=true
	export SCOREP_HIP_ENABLE='api','kernel','kernel_callsite','malloc','memcpy','sync'
	export SCOREP_HIP_ACTIVITY_BUFFER_SIZE=1M
	export SCOREP_MEMORY_RECORDING=false
	export SCOREP_IO_POSIX=false
fi
