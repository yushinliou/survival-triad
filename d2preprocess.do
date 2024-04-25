*20210218 created by Yu-Shin
*for 20220222下午 中研院報告

clear all

*設定工作目錄
cd "/Users/liuyuxin/Desktop/research/tradic/dofile"
*做出d1 alter名單，標記出誰有d2-alter以及誰有成功tie的d2alter
*重新命名方便合併
use "/Users/liuyuxin/Desktop/fblonely/analysis_fblonely/alltie/outcome/all_tie.dta"
*區分連結類型
keep if Ownerfbid == From_id | Ownerfbid == From_id_p
g d1act = 1 if Ownerfbid == From_id_p
recode d1act(.=0)
g d1_alterid = From_id if d1act == 1
*d1_alterid
replace d1_alterid = From_id_p if d1act == 0
bysort Ownerfbid d1_alterid:egen d1firstime = min(createdtime_date_d)
format d1firstime %tc
keep Ownerfbid tie_type d1act d1_alterid d1firstime
sort Ownerfbid d1_alterid d1firstime tie_type d1act
order Ownerfbid d1_alterid d1firstime tie_type d1act
duplicates drop Ownerfbid d1_alterid d1firstime, force
save "/Users/liuyuxin/Desktop/research/tradic/tmp/d1_alterid.dta", replace

*d2_alterid
*做一個資料框架，去除ego包含在裡面的連結
use "/Users/liuyuxin/Desktop/fblonely/analysis_fblonely/alltie/outcome/all_tie.dta"
drop if Ownerfbid == From_id | Ownerfbid == From_id_p
*合併，分別檢驗From_id From_id_p是否為d1
rename From_id d1_alterid
merge m:1 Ownerfbid d1_alterid using "/Users/liuyuxin/Desktop/research/tradic/tmp/d1_alterid.dta", keepusing(d1_alterid d1firstime) generate(From_isd1)
drop if From_isd1 == 2
recode From_isd1(1=0)(3=1)
rename d1firstime d1firstime_F
rename d1_alterid From_id
rename From_id_p d1_alterid
merge m:1 Ownerfbid d1_alterid using "/Users/liuyuxin/Desktop/research/tradic/tmp/d1_alterid.dta", keepusing(d1_alterid d1firstime) generate(Fromp_isd1)
drop if Fromp_isd1 == 2
rename d1firstime d1firstime_Fp
recode Fromp_isd1(1=0)(3=1)
rename d1_alterid From_id_p
*檢驗連結發生的當下是不是d1
replace Fromp_isd1 = 0 if createdtime_date_d < d1firstime_Fp
replace From_isd1 = 0 if createdtime_date_d < d1firstime_F
*只留下只有其中一人是d1的連結，即為d1-d2連接
keep if  From_isd1 + Fromp_isd1 == 1
*做d1_alterid, d2_alterid
g d1_alterid = From_id if From_isd1 == 1
replace d1_alterid = From_id_p if Fromp_isd1 == 1
g d2_alterid = From_id if From_isd1 == 0
replace d2_alterid = From_id_p if Fromp_isd1 == 0
bysort Ownerfbid d2_alterid:egen d2firstime = min(createdtime_date_d)
format d2firstime %tc
*若From_id是d1，那就是由d1主動，d2被動
g d2act = 0 if From_isd1 == 1
recode d2act(.=1)
*計算接觸過d2alter的d1
preserve
*d1第一次接觸此d2
bysort Ownerfbid d2_alterid d1_alterid:egen d1d2firstime = min(createdtime_date_d)
format d1d2firstime %tc
sort createdtime_date_d
duplicates drop Ownerfbid d1_alterid d2_alterid d2firstime,force
g d1firstime = d1firstime_F
replace d1firstime = d1firstime_Fp if d1firstime == .
format d1firstime %tc
keep Ownerfbid d2_alterid d1_alterid d2firstime d1firstime d1d2firstime tie_type d2act 
order Ownerfbid d2_alterid d1_alterid d2firstime d1firstime d1d2firstime tie_type d2act 
sort d2act tie_type d1d2firstime d2firstime d1firstime d1_alterid d2_alterid Ownerfbid 
save "/Users/liuyuxin/Desktop/research/tradic/tmp/d1d2firstime.dta",replace
keep Ownerfbid d2_alterid d1_alterid d2firstime tie_type d2act
sort Ownerfbid d2_alterid d1_alterid d2firstime tie_type d2act
order Ownerfbid d2_alterid d1_alterid d2firstime tie_type d2act
duplicates tag Ownerfbid d2_alterid,g(d1num)
replace d1num = d1num+1
keep Ownerfbid d2_alterid d1num
duplicates drop
save "/Users/liuyuxin/Desktop/research/tradic/tmp/d1num.dta",replace
restore
*恢復
keep Ownerfbid tie_type d2_alterid d2firstime d2act
sort Ownerfbid d2_alterid d2firstime d2act tie_type
order Ownerfbid d2_alterid d2firstime d2act tie_type
duplicates drop Ownerfbid d2_alterid d2firstime, force
*記錄這些d2有沒有在未來變成d1
rename d2_alterid d1_alterid
merge m:1 Ownerfbid d1_alterid using "/Users/liuyuxin/Desktop/research/tradic/tmp/d1_alterid.dta", keepusing(d1_alterid d1firstime d1act) generate(transfer)
rename d1_alterid d2_alterid
drop if transfer == 2
recode transfer(3=1)(1=0)
save "/Users/liuyuxin/Desktop/research/tradic/tmp/d2_alterid.dta", replace
clear

*survival模型
*合併一年的時間段
use "/Users/liuyuxin/Desktop/research/tradic/tmp/d2_alterid.dta"
merge m:1 Ownerfbid using "/Users/liuyuxin/Desktop/fblonely/analysis_fblonely/alltie/tmp/eventperiod.dta", keepusing(eventover) 
drop if _merge != 3
drop _merge
*設定時間範圍，只保留d2firstime研究期間內的
g daylong = (eventover - d2firstime) / 86400000
keep if daylong >= 0 & daylong <= 365
*eventover原本是訪談時間，若有三角形轉換則改為閉合時間
replace eventover = d1firstime if transfer == 1
*duration
g duration = (eventover - d2firstime) / 86400000
*d1act = 1 代表 trans的時候是 d2主動接近ego
*d1firstime代表的是d2成為d1的時間
*d2act = 1 代表 d2成為d1的時候是 d2主動接近ego

save "d2_survival.dta", replace
clear


cd "/Users/liuyuxin/Desktop/research/tradic/dofile"
*C2 C4 ego線上特徵
*為合併線上變數作準備
*相對路徑
*import delimited "./var/ego_firstime.csv" , bindquote(strict) encoding(utf8) stringcols(2)
use "./var/ego_firstime.dta"
save "./var/ego_firstime.dta",replace
clear
use "d2_survival.dta"
merge m:1 Ownerfbid using "./var/ego_firstime.dta",keepusing(ego_firstime)
*刪除掉沒有最早歷史紀錄的ego
drop if _merge != 3
drop _merge
*datetime to date
g ego_firstday = dofc(ego_firstime)
format ego_firstday %td
*使用臉書的天數
g ego_fbday = ((d2firstime - ego_firstime) / 86400000) 
g ego_fbday100 = ((d2firstime - ego_firstime) / 86400000) / 100
save "d2_survival.dta", replace
clear

import delimited "./var/egotime.csv" , bindquote(strict) encoding(utf8) stringcols(2)
g Ownerfbid = string(ownerfbid, "%20.0f")
save "./var/egotime.dta", replace
use "d2_survival.dta"
merge m:1 Ownerfbid d2_alterid using "./var/egotime.dta",keepusing(egocomment egocomment_m egotag egotag_m d2com d2com_month d2tag d2tag_m egolcc)

*2641個觀察值在合併線上資料的時候被刪除，待確認為什麼沒有這些資料
drop if _merge != 3
drop _merge
*重新命名以方便跑前任助理的code
rename egolcc ego_density
rename egocomment ego_comment
rename egotag ego_posttag
rename egocomment_m ego_comment_mon
rename egotag_m ego_posttag_mon
rename d2com d2_comment
rename d2tag d2_posttag
rename d2com_month d2_comment_mon
rename d2tag_m d2_posttag_mon

*C1訪談資料
*合併訪談資料變數年齡、性別、教育年數，外向性
merge m:1 Ownerfbid using "/Users/liuyuxin/Desktop/fblonely/analysis_fblonely/model/outcome/ego_survey_775obs.dta", keepusing(egoextra egofemale egoeduyr egoage f26)
drop if _merge != 3
drop _merge
g egoage_fb100 = ego_fbday100 * egoage
save "d2_survival.dta", replace
clear

*C3 d1線上資料
******整理python導出的資料以方便合併********
import delimited "./var/d1time.csv" , bindquote(strict) encoding(utf8) stringcols(2)
*計算d2alter擁有的d1數量
g Ownerfbid = string(ownerfbid,"%20.0f")
duplicates tag d2_alterid,g(d2_contactppl)
replace d2_contactppl = d2_contactppl + 1
preserve
duplicates drop Ownerfbid d2_alterid d2_contactppl, force
save "./var/d2_contactppl.dta", replace
restore
*d1進入網絡到d2進入網絡的時間平均
g d1firstday = date(substr(d1firstime,1,10), "YMD")
g d2firstday = date(substr(d2firstime,1,10), "YMD")
format d1firstday d2firstday %td
g d1_tieego_100 = (d2firstday - d1firstday)/100
bysort Ownerfbid d2_alterid:egen d1_tieego_mean100 = mean(d1_tieego_100)
duplicates drop Ownerfbid d2_alterid d1_tieego_mean100, force
save "./var/d1_tieego_mean100_d2.dta", replace
clear
*d1lcc
import delimited "./var/d1lcc.csv" , bindquote(strict) encoding(utf8) stringcols(2)
g Ownerfbid = string(ownerfbid,"%20.0f")
*4300個缺失值
destring d1lcc,g(d1_density) force
*先用零來處理缺失值
replace d1_density = 0 if d1_density ==.
bysort Ownerfbid d2_alterid:egen d1_density_mean = mean(d1_density)
duplicates drop Ownerfbid d2_alterid d1_density_mean, force
save "./var/d1_density_mean.dta", replace
clear

*d1com
import delimited "./var/d1time_com.csv" , bindquote(strict) encoding(utf8) stringcols(2)
*數字轉字串
g Ownerfbid = string(ownerfbid,"%20.0f")
*字串轉數字
destring d1com_monthly,g(d1_comment_mon) force
rename d1_alterid D1_alterid
g d1_alterid = string(D1_alterid,"%20.0f")
*先用總評論次數來處理缺失值
replace d1_comment_mon = d1com if d1_comment_mon ==.
*d1iscom有評論或者沒評論
g d1iscom = 1 if d1com > 0
replace d1iscom =0 if d1com == 0
*計算對ego-d2他的d1有評論的次數
duplicates tag Ownerfbid d2_alterid,g(d1num)
replace d1num = d1num+1
bysort Ownerfbid d2_alterid:egen d1iscomnum = sum(d1iscom)
bysort Ownerfbid d2_alterid:g d1_comment_mean = d1iscomnum / d1num
*計算某對ego-d2他們的d1平均每個月評論多少次
bysort Ownerfbid d2_alterid:egen d1_comment_mon_mean = mean(d1_comment_mon)
duplicates drop Ownerfbid d2_alterid d1_comment_mon_mean d1_comment_mean, force
save "./var/d1_comment.dta", replace
clear

*d1tag
import delimited "./var/d1time_tag.csv" , bindquote(strict) encoding(utf8) stringcols(2)
g Ownerfbid = string(ownerfbid,"%20.0f")
*先用總標記次數來處理缺失值
replace d1tag_monthly = d1tag if d1tag_monthly ==.
g d1istag = 1 if d1tag > 0
replace d1istag = 0 if d1tag == 0
*計算對ego-d2他的d1有評論的次數
bysort Ownerfbid d2_alterid:egen d1num = count(d1_alterid)
bysort Ownerfbid d2_alterid:egen d1istagnum = sum(d1istag)
bysort Ownerfbid d2_alterid:g d1_posttag_mean = d1istagnum / d1num
*計算某對ego-d2他們的d1平均每個月評論多少次
bysort Ownerfbid d2_alterid:egen d1_posttag_mon_mean = mean(d1tag_monthly)
duplicates drop Ownerfbid d2_alterid d1_posttag_mon_mean d1_posttag_mean, force
save "./var/d1_posttag.dta", replace
clear

*d1_neighbor
import delimited "./var/d1_neighbor.csv" , bindquote(strict) encoding(utf8) stringcols(2)
*數字轉字串
g Ownerfbid = string(ownerfbid,"%20.0f")
*字串轉數字
destring d1_neighbor,replace force
*先用總評論次數來處理缺失值
replace d1_neighbor = 2 if d1_neighbor ==.
bysort Ownerfbid d2_alterid:egen d1_neighbor_mean = mean(d1_neighbor)
duplicates drop Ownerfbid d2_alterid d1_neighbor_mean , force
save "./var/d1_neighbormean.dta", replace
clear

****跟進行survival的檔案合併
use "d2_survival.dta"
merge 1:m Ownerfbid d2_alterid using "./var/d1_tieego_mean100_d2.dta", keepusing(d1_tieego_mean d2_contactppl)
drop if _merge == 2
drop _merge
duplicates report Ownerfbid d2_alterid
merge 1:m Ownerfbid d2_alterid using "./var/d1_neighbormean.dta", keepusing(d1_neighbor_mean)
*沒有遺漏，全部有對上
drop if _merge == 2
drop _merge
duplicates report Ownerfbid d2_alterid
merge 1:m Ownerfbid d2_alterid using "./var/d1_posttag.dta", keepusing(d1_posttag_mon_mean d1_posttag_mean)
*沒有遺漏，全部有對上
drop if _merge == 2
drop _merge
duplicates report Ownerfbid d2_alterid
merge 1:m Ownerfbid d2_alterid using "./var/d1_comment.dta", keepusing(d1_comment_mon_mean d1_comment_mean)
*沒有遺漏，全部有對上
drop if _merge == 2
drop _merge
duplicates report Ownerfbid d2_alterid
merge 1:m Ownerfbid d2_alterid using "./var/d1_density_mean.dta", keepusing(d1_density_mean)
*沒有遺漏，全部有對上
drop if _merge == 2
drop _merge


*創造變數
gen egoextra2= egoextra^2
gen egoage2= egoage^2
*gen ego_fbday100= ego_fbday/100
*gen d1_tieego_mean100= d1_tieego_mean/100
*gen egoage_fb100=egoage*ego_fbday100
gen egoposttagmon_fb100=ego_posttag_mon*ego_fbday100
gen egoposttagmon_commentmon=ego_posttag_mon*ego_comment_mon
gen d1_neighbor_mean_1=1/ d1_neighbor_mean
gen d1_neighbor_mean_2=(1/ d1_neighbor_mean)*(1/ d1_neighbor_mean)

*創六個虛擬變數(與之前定義相反，ex:1=have comment,0=no comment)
gen ego_comment1=0
replace ego_comment1=1 if ego_comment > 0
gen ego_posttag1=0
replace ego_posttag1=1 if ego_posttag > 0
gen d1_comment_mean1=0
replace d1_comment_mean1=1 if d1_comment_mean > 0
gen d1_posttag_mean1=0
replace d1_posttag_mean1=1 if d1_posttag_mean > 0
gen d2_comment1=0
replace d2_comment1=1 if d2_comment > 0
gen d2_posttag1=0
replace d2_posttag1=1 if d2_posttag > 0


drop if egoextra==.| egofemale==.| egoeduyr==.| egoage==.| ego_density==.


************************************************
*d2_survival_label

label var Ownerfbid "egoid"
label var d2_alterid "degree-2 alterid"

*C1 label
*label var extro "SRDA 2017 f18"
label var egoextra "extroversion"
*label var female "is female or not"
label var egofemale "female"
label var egoeduyr "years of education"
label var egoage "age"

*C2 label (ego online)
*label var ego_fbday "from d2firstime to egofirstime"
*label var ego_fbday100 "from d2firstime to egofirstime(100days)"
label var ego_fbday "total days on FB"
label var ego_fbday100 "total days on FB(/100days)"
label var egoage_fb100 "interaction:age and total days"
label var ego_density "local clustering"
label var ego_comment1 "commented"
label var ego_comment_mon "comments per month"
label var ego_posttag1 "was tagged"
label var ego_posttag_mon "tags per month"

*c3 label (d1 online action)
label var d1_tieego_mean100 "duration of tie with ego"
label var d1_neighbor_mean_1 "neighbor"
label var d1_neighbor_mean_2 "neighbor^2"
label var d1_density_mean "local clustering coefficient"
label var d1_comment_mean1 "commented"
label var d1_comment_mon_mean "comments per month"
label var d1_posttag_mean1 "was tagged"
label var d1_posttag_mon_mean "tags per month"

*C4 label (d2)
label var d2_contactppl "number of degree-1 alters"
label var d2_comment1 "commented"
label var d2_comment_mon "comments per month"
label var d2_posttag1 "was tagged"
label var d2_posttag_mon "tags per month"


label var d2firstime "the firsttime alter became d2_alter"
label var d2act "wehether alter connect d1 when alter become d2"
*label define D2ACT 1"alter connect d1" 0"d1 connect alter"
*label value 2act D2ACT
label var tie_type "when alter become d2, tietype"
label var d1firstime "the time when d2 become d1(if it happens)"
label var d1act "whether d2 alter connect ego, when d2 become d1"
label var transfer "whether d2 transfer to d1 or not"
label define TRANSFER 1"trans" 0"no trans"
label value transfer TRANSFER
label define EGOFEMALE 1"female" 0"male"
label value egofemale EGOFEMALE
label var eventover "interview time(or when d2 trans)"
label var daylong "from d2firstime to interviewtime"
label var duration "from d2 firstime to eventover"
*label var extro "SRDA 2017 f18"
*label var age "SRDA 2017 a2"
*label var agesqr "age*age"
*label var ego_firstime "the first time record ego use facebook(string)"
*label var ego_firstday "the firstdate record ego use facebook"
*label var egofirstime "the first time record ego use facebook(datetime)"



