#run collect_times perl script
# e.g. 
# system("perl code/perl/collect_times 10000 < data/input/aligned_D1_sequences_V3.log > data/output/jumpTimes.txt", intern = FALSE)

library(here)

# Compose the paths using here:
perl_script <- here("code", "perl", "collect_times")
input_log   <- here("data", "input", "aligned_D1_sequences_V3.log")
output_file <- here("data", "output", "jumpTimes.txt")

# Construct the command string. We use 'perl' to run the script.
cmd <- sprintf("perl %s 10000 < %s > %s", perl_script, input_log, output_file)

# Run the command
system(cmd, intern = FALSE)