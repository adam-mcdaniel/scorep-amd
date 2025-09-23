if [ -z $INSTALL_DIR ]; then
	echo "Please source setup-env.sh in the root directory of this project"
	echo "before sourcing this file."
else
	export SCOREP_ENABLE_PROFILING=false
	export SCOREP_ENABLE_TRACING=true
	export SCOREP_ENABLE_UNWINDING=false
	export SCOREP_VERBOSE=false
	export SCOREP_TOTAL_MEMORY=4G
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
	export SCOREP_TRACING_CONVERT_CALLING_CONTEXT_EVENTS=true
	export SCOREP_FILTERING_FILE=''
	export SCOREP_SUBSTRATE_PLUGINS=''
	export SCOREP_SUBSTRATE_PLUGINS_SEP=','
	export SCOREP_LIBWRAP_PATH=''
	export SCOREP_LIBWRAP_ENABLE=''
	export SCOREP_LIBWRAP_ENABLE_SEP=','
	export SCOREP_METRIC_RUSAGE=''
	export SCOREP_METRIC_RUSAGE_PER_PROCESS=''
	export SCOREP_METRIC_RUSAGE_SEP=','
	export SCOREP_METRIC_PLUGINS='arocm_smi_plugin,coretemp_plugin'
	export SCOREP_METRIC_PLUGINS_SEP=','
	export SCOREP_METRIC_PERF=''
	export SCOREP_METRIC_PERF_PER_PROCESS=''
	export SCOREP_METRIC_PERF_SEP=','
	export VT_AROCM_SMI_BUF_SIZE=128M
	export VT_CORETEMP_BUF_SIZE=128M
	export SCOREP_METRIC_AROCM_SMI_INTERVAL_US=1000
	export SCOREP_METRIC_AROCM_SMI_PLUGIN='rocm_smi:::gpu_clk_freq_System:device=0:current,rocm_smi:::gpu_clk_freq_System:device=2:current,rocm_smi:::gpu_clk_freq_System:device=4:current,rocm_smi:::gpu_clk_freq_System:device=6:current,rocm_smi:::temp_current:device=0:sensor=1,rocm_smi:::temp_current:device=2:sensor=1,rocm_smi:::temp_current:device=4:sensor=1,rocm_smi:::temp_current:device=6:sensor=1,rocm_smi:::energy_count:device=0,rocm_smi:::energy_count:device=2,rocm_smi:::energy_count:device=4,rocm_smi:::energy_count:device=6,rocm_smi:::power_average:device=0:sensor=0,rocm_smi:::power_average:device=2:sensor=0,rocm_smi:::power_average:device=4:sensor=0,rocm_smi:::power_average:device=6:sensor=0'
	export SCOREP_METRIC_CORETEMP_INTERVAL_US=1000
	# Needs timestamps for cray metrics
	export SCOREP_METRIC_CORETEMP_PLUGIN='coretemp:::craypm:power,coretemp:::craypm:energy,coretemp:::craypm:freshness,coretemp:::craypm:accel0_energy,coretemp:::craypm:accel0_power,coretemp:::craypm:accel1_energy,coretemp:::craypm:accel1_power,coretemp:::craypm:accel2_energy,coretemp:::craypm:accel2_power,coretemp:::craypm:accel3_energy,coretemp:::craypm:accel3_power'
	export SCOREP_SAMPLING_EVENTS='timer@1000'
	export SCOREP_SAMPLING_SEP=','
	export SCOREP_TOPOLOGY_PLATFORM=true
	export SCOREP_TOPOLOGY_PROCESS=true
	export SCOREP_HIP_ENABLE=none
	# export SCOREP_HIP_ACTIVITY_BUFFER_SIZE=512M
	export SCOREP_MEMORY_RECORDING=false
	export SCOREP_IO_POSIX=false
fi
