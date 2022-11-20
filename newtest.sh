#! /bin/bash
#Author: sushant dhopat
#sub enum
echo -e "\e[1;32m "
target=$1
wordlist=/root/all.txt
altdnswords=/root/altdns.txt
fuzz=/root/fuzz.txt

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

echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -active -d $target -brute -w $wordlist -config /root/config.ini | tee new-$target/$target-amass.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the sublist3r \e[0m"
python3 /root/Sublist3r/sublist3r.py -d $target -o new-$target/$target-sublist.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the censys \e[0m"
python3 /root/censys-subdomain-finder/censys-subdomain-finder.py $target | tee new-$target/$target-censys.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the crt.sh \e[0m"
curl -s https://crt.sh/\?q\=$target\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee new-$target/$target-crt.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the wayback \e[0m"
curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$1&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | tee new-$target/$target-wayback.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the riddler.io \e[0m"
curl -s "https://riddler.io/search/exportcsv?q=pld:$1" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee new-$target/$target-riddler.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the securitytrails \e[0m"
curl -s "https://securitytrails.com/list/apex_domain/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$1" | sort -u | tee new-$target/$target-securitytrails.txt

#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt new-$target/$target-crt.txt new-$target/$target-wayback.txt new-$target/$target-securitytrails.txt new-$target/$target-censys.txt new-$target/$target-riddler.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt

echo -e "\e[1;34m [+] making resolvers \e[0m"
dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 200 -o /root/resolvers.txt
resolver=/root/resolvers.txt

echo -e "\e[1;34m [+] Bruteforce subdomain throw puredns \e[0m"
puredns bruteforce -r $resolver $wordlist $target | tee new-$target/bruteforce-$target.txt

echo -e "\e[1;34m [+] Running dnsgen -perm \e[0m"
cat new-$target/allsortedsub-$target.txt | dnsgen - | tee new-$target/dnsgen-$target.txt

echo -e "\e[1;34m [+] Bruteforcing subdomains throw gotator \e[0m"
gotator -sub new-$target/allsortedsub-$target.txt -perm $perm -depth 3 -numbers 10 -md -prefixes -adv -mindup | uniq | tee new-$target/gotator-$target.txt

cat new-$target/*.txt > new-$target/unsortedresolve-$target.txt
rm new-$target/allsortedsub-$target.txt new-$target/bruteforce-$target.txt new-$target/dnsgen-$target.txt new-$target/gotator-$target.txt
cat new-$target/unsortedresolve-$target.txt | sort -u | tee new-$target/for-resolve-$target.txt
rm new-$target/unsortedresolve-$target.txt

echo -e "\e[1;34m [+] Resolving subdomain throw puredns \e[0m"
puredns resolve -r $resolver new-$target/for-resolve-$target.txt | tee new-$target/resolved-$target.txt

echo -e "\e[1;34m [+] Gathering IP address of resolved subdomain \e[0m"
bash /root/dtoip.sh new-$target/resolved-$target.txt new-$target/ips.txt

mkdir new-$target/valid

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/for-resolve-$target.txt | httpx -silent | tee new-$target/valid/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Running Httpx for live ips \e[0m"
cat new-$target/ips.txt | httpx -silent | tee new-$target/valid/validips-$target.txt

mkdir new-$target/screesnhots
echo -e "\e[1;34m [+] performing screesnhots live hosts  \e[0m"
gowitness -F file -f new-$target/valid/validsubdomain-$target.txt -p new-$target/screesnhots/validdomainscreenshots

echo -e "\e[1;34m [+] performing screesnhots on IPs  \e[0m"
gowitness -F file -f new-$target/valid/validips-$target.txt -p new-$target/screesnhots/resolvedipscreenshots

mkdir new-$target/ffuf

echo -e "\e[1;34m [+] Running ffuf on validsubdomain GET based \e[0m"
ffuf -u W2/W1 -w $fuzz:W1,/new-$target/valid/validsubdomain-$target.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/ffuf/ffufresult

echo -e "\e[1;34m [+] Running ffuf on validsubdomain POST based \e[0m"
ffuf -X POST -u W2/W1 -w $fuzz:W1,/new-$target/valid/validsubdomain-$target.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/ffuf/ffufresult2

mkdir new-$target/nuclei

echo -e "\e[1;34m [+] Running nuclie-templates on validsubdomain \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /root/nuclei-templates | tee new-$target/nuclei/nuclei

mkdir new-$target/nmap

echo -e "\e[1;34m [+] performing nmap scan on resoved ip  \e[0m"
nmap -p 1-65535 -sV -iL new-$target/ips.txt -oN new-$target/ipscanoutput.txt -oX new-$target/nmap/ipscanoutput.xml

echo -e "\e[1;34m [+] performing nmap scan on resolved domains  \e[0m"
nmap -p 1-65535 -sV -iL new-$target/resolved-$target.txt -oN new-$target/domainscanoutput.txt -oX new-$target/nmap/domainscanoutput.xml

echo -e "\e[1;34m [+] performing screesnhots on open nmap ports  \e[0m"
gowitness nmap -F -f new-$target/nmap/ipscanoutput.xml --open --service-contains http -p new-$target/screesnhots/ipscanoutputscreenshots
gowitness nmap -F -f new-$target/nmap/domainscanoutput.xml --open --service-contains http -p new-$target/screesnhots/domainscanoutputscreenshots

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/for-resolve-$target.txt | wc -w

echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/valid/validsubdomain-$target.txt | wc -w

echo -e "\e[1;34m [+] finding login pages \e[0m"
cat new-$target/valid/validsubdomain-$target.txt | nuclei -t /root/temp/login.yaml | tee new-$target/loginpage.txt

echo -e "\e[1;34m [+] performing tech wise briteforce \e[0m"

file= new-$target/valid/validsubdomain-$target.txt
mkdir new-$target/tech

cat $file | nuclei -t /root/nuclei-templates/technologies/apache | tee new-$target/tech/apache-domains.txt

if [ "apache-domains.txt" == 0 ]; then
  echo "no any apache domains found"
else
  ffuf -u W2/W1 -w /root/tech/apache.txt:W1,new-$target/tech/apache-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-apache-files
fi

cat $file | nuclei -t /root/nuclei-templates/technologies/aem-cms.yaml | tee new-$target/tech/aem-domains.txt

if [ "aem-domains.txt" == 0 ]; then
  echo "no any aem domains found"
else
  ffuf -u W2/W1 -w /root/tech/aem.txt:W1,new-$target/tech/aem-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-aem-files
  ffuf -u W2/W1 -w /root/tech/adobe.txt:W1,new-$target/tech/aem-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-adobe-files
fi

cat $file | nuclei -t /root/nuclei-templates/technologies/oracle | tee new-$target/tech/oracle-domains.txt

if [ "oracle-domains.txt" == 0 ]; then
  echo "no any oracle domains found"
else
  ffuf -u W2/W1 -w /root/tech/oracle.txt:W1,new-$target/tech/oracle-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-oracle-files
fi

cat $file | nuclei -t /root/nuclei-templates/technologies/microsoft | tee new-$target/tech/microsoft-domains.txt

if [ "microsoft-domains.txt" == 0 ]; then
  echo "no any microsoft domains found"
else
  ffuf -u W2/W1 -w /root/tech/aspx.txt:W1,new-$target/tech/microsoft-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-microsoft-files
fi

cat $file | nuclei -t /root/nuclei-templates/technologies/php-detect.yaml | tee new-$target/tech/php-domains.txt

if [ "php-domains.txt" == 0 ]; then
  echo "no any php domains found"
else
  ffuf -u W2/W1 -w /root/tech/php.txt:W1,new-$target/tech/php-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-php-files
fi

cat $file | nuclei -t /root/nuclei-templates/technologies/nginx | tee new-$target/tech/nginx-domains.txt

if [ "nginx-domains.txt" == 0 ]; then
  echo "no any nginx domains found"
else
  ffuf -u W2/W1 -w /root/tech/nginx.txt:W1,new-$target/tech/nginx-domains.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/tech/valid-nginx-files
fi

echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"
