#! /bin/bash
#Author: sushant dhopat
#Basic subdomain recon tool
#Tools:-
#Assetfinder 
#subfinder
#amass
#sublist3r
#httpx

echo -e "\e[1;32m "
#Need resolvers you can get from amass you can also generate with shuffledns store them in specifc directory and add this directory path in resolver variable
resolver=/Users/sushantdhopat/Desktop/resolvers.txt
wordlist=/home/sushant/subdomains.txt
target=$1

if [ $# -gt 2 ]; then
       echo "./sub.sh <domain>"
       echo "./sub.sh google.com"
       exit 1
fi


if [ ! -d new-$target ]; then
       mkdir new-$target
 else
    echo "sorry we cant create the same file in same directory please remove first one new-$target !!!Thanks"
    exit 1

fi

#passive subdomain enumeration with different tool

echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -passive -d $target | tee new-$target/$target-amass.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the sublist3r \e[0m"
python3 /Users/sushantdhopat/Desktop/Sublist3r/sublist3r.py -d $target -o new-$target/$target-sublist.txt
#echo -e "\e[1;34m [+] Enumerating Subdomain from the censys \e[0m"
#python3 /Users/sushantdhopat/Desktop/censys-subdomain-finder/censys-subdomain-finder.py $target | tee new-$target/$target-censys.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the crt.sh \e[0m"
curl -s https://crt.sh/\?q\=$target\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee new-$target/$target-crt.txt


#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt new-$target/$target-crt.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt

echo -e "\e[1;34m [+] Running shuffledns  for resolve host \e[0m"
shuffledns -d $target -list new-$target/allsortedsub-$target.txt -r $resolver | tee new-$target/$target-resolved.txt

echo -e "\e[1;34m [+] Gathering IP address of resolved subdomain \e[0m"
bash /Users/sushantdhopat/Desktop/dtoip/dtoip.sh new-$target/$target-resolved.txt new-$target/ips.txt

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/allsortedsub-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/allsortedsub-$target.txt | wc -w
echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/validsubdomain-$target.txt | wc -w
echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"
