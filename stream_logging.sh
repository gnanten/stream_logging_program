#using awk as there is no inbuilt yaml parser available with shell

v_max_iterative_time=$(awk '{if ($1=="max_iterative_time:")  print $2}' ./rules/input_stream_rules.yml) 
v_max_response_time=$(awk '{if ($1=="max_response_time:")  print $2}' ./rules/input_stream_rules.yml)
v_max_error_tolerance=$(awk '{if ($1=="max_error_count:")  print $2}' ./rules/input_stream_rules.yml) 
v_max_error_interval=$(awk '{if ($1=="max_error_interval:")  print $2}' ./rules/input_stream_rules.yml)
pwd

#mkdir temp || true
egrep "^*\[*ms\]" ./input_log/log.txt | sort -nk4 > ./temp/pid_log.temp

pid_flag=0
one_time=0
v_count=0
v_error_count=0
rt_file="./temp/pid_log.temp"
while IFS= read line
do
v_resp=`echo $line |grep "PID"| awk '{print $5}' | cut -d "[" -f2 | cut -d "m" -f1`
v_pid=`echo $line |grep "PID" | awk '{print $4}' | cut -d ']' -f1`
v_sec_time=`echo $line |grep "PID"| awk '{print $2}' | cut -d ':' -f3`
v_minute_time=`echo $line |grep "PID"| awk '{print $2}' | cut -d ':' -f2`
v_error_flag=`echo $line |grep -c  "\[ERROR\]"`

#echo $v_error_cnt v_error_cnt

if [[ $one_time -eq 0 ]] # runs only for the first time i.e., one time per run
then
x_resp=$v_resp
x_pid=$v_pid 
x_sec_time=$v_sec_time #capturing previous seconds
f_sec_time=$v_sec_time #first capture per pid
x_minute_time=$v_minute_time #capturing previous minutes
f_minute_time=$v_minute_time #first capture per pid
one_time=1
fi


if [[ $x_pid -eq $v_pid ]] 
then

if [[ $v_resp -gt $v_max_response_time && $((v_sec_time-f_sec_time)) -ge $v_max_iterative_time ]]
then 
echo rule1 is broken. hence logging to this file. >> ./OutStreamed_log/outstream_log.txt #rule1
echo $line >> ./OutStreamed_log/outstream_log.txt
fi


v_error_count=$((v_error_count+v_error_flag))


if [[ $v_error_count -ge 2 && $v_error_flag -ne 0 && $((v_minute_time-f_minute_time)) -ge $v_max_error_interval ]]
then
echo rule2 is broken. hence logging to this file. >> ./OutStreamed_log/outstream_log.txt #rule2
echo $line >> ./OutStreamed_log/outstream_log.txt
fi

else
f_sec_time=$v_sec_time
f_minute_time=$v_minute_time
v_error_count=0
fi

x_resp=$v_resp
x_pid=$v_pid
x_sec_time=$v_sec_time
x_minute_time=$v_minute_time
done <"$rt_file"
#rm -fr ./temp/pid_log.temp # commented for logging purpose
