#! /bin/bash
#Author: sushant dhopat
#Basic subdomain recon tool
#Tools:-
#Assetfinder 
#subfinder
#amass
#sublist3r
#puredns
#httpx

echo -e "\e[1;32m "
#Need resolvers you can get from amass you can also generate with shuffledns store them in specifc directory and add this directory path in resolver variable
resolver=/home/sushant/resolvers #its a subbrute resolver path just pass your own path of subbrute tool
wordlist=/home/sushant/all.txt #its a wordlist for bruteforce subdomain just pass any sub bruteforce wordlist
words=/home/sushant/words.txt
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
sublist3r -d $target -o new-$target/$target-sublist.txt

#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt
#new file generated new-$target/allsortedsub-$target.txt

#echo -e "\e[1;34m [+] grab all unique second-level domains available to us \e[0m"
#cat new-$target/allsortedsub-$target.txt | awk -v FS=. '{print $(NF-1)}' | grep -v @ | sort -u | tee new-$target/slword.txt

#echo -e "\e[1;34m [+] adding $taraget at end to check possbile domains \e[0m"
#cat new-$target/slword.txt | awk {'print $1".'$target'"'} | tee new-$target/possibledomain.txt
#rm new-$target/slword.txt

#echo -e "\e[1;34m [+] Bruteforce subdomain throw puredns \e[0m"
#puredns bruteforce -r $resolver $wordlist $target | tee new-$target/bruteforce-$target.txt

#cat new-$target/*.txt > new-$target/for-resolve-$target.txt
#echo -e "\e[1;34m [+] Resolving subdomain throw puredns \e[0m"
#puredns resolve -r $resolver new-$target/for-resolve-$target.txt | tee new-$target/resolved-$target.txt
#cat new-$target/*.txt > new-$target/forsort-$target.txt
#rm new-$target/allsortedsub-$target.txt new-$target/bruteforce-$target.txt new-$target/resolved-$target.txt
#cat new-$target/forsort-$target.txt | sort -u | tee new-$target/final-$target.txt
#rm new-$target/forsort-$target.txt new-$target/for-resolve-$target.txt
#cat new-$target/final-$target.txt

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/allsortedsub-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/allsortedsub-$target.txt | wc -w
echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/validsubdomain-$target.txt | wc -w

echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"
