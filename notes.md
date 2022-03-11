# max vowels, incude y
```shell
{ bgame wordle -p '[aeiouy]{5}'; bgame wordle -p '[^aeiou][aeiouy]{4}'; bgame wordle -p '[aeiouy][^aieou][aeiouy]{3}'; bgame wordle -p '[aeiouy]{2}[^aeiou][aeiouy]{2}'; bgame wordle -p '[aeiouy]{3}[^aeiou][aeiouy]{1}'; bgame wordle -p '[aeiouy]{4}[^aeiou]'; } | sort | uniq
```
(only looking at possible winners. removed ones with duplicate letters)

audio
bayou

(from all valid words. removed ones with duplicate letters)

adieu
aiery
auloi
aurei
ayrie
boyau
coyau
louie
miaou
noyau
ouija
ourie
pioye
ulyie
uraei
youse
yowie
