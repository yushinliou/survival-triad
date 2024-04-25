*lcc 20230122
*for 2/1, 中研院臉書資料會議


****************** d2 survival
clear all

*頭三個月進入ego網絡的人都會transfer
local inDate = "0212"
local outDate = "0222"

cd "/Users/liuyuxin/Desktop/research/fb_college_traid/tmp"
use "d2survival_inclass_23`inDate'.dta"

summarize ego_posttag_mon, detail

****************
* make sure no missing value
drop if d1_density_mean == .

label var ego_posttag_mon "average of ego be tagged per month"
histogram ego_posttag_mon, color(gray) percent scheme(s1color) title("Histagram of ego tagged (initiator perspective)")
graph export "../outcome/`outDate'/egod2/histEgoTag.png",replace

*replace ego_density = ego_density*100
*replace d1_density_mean = d1_density_mean*100
*replace d2_density = d2_density*100

replace ego_comment_mon = log(ego_comment_mon+1)
replace d2_comment_mon = log(d2_comment_mon+1)
replace d1_comment_mon_mean = log(d1_comment_mon_mean+1)

replace ego_posttag_mon = log(ego_posttag_mon+1)
replace d2_posttag_mon = log(d2_posttag_mon+1)
replace d1_posttag_mon_mean = log(d1_posttag_mon_mean+1)

* generate interaction and square variable
g egoextra2 = egoextra * egoextra
g d1extra_mean2 = d1extra_mean * d1extra_mean
g d2extra2 = d2extra * d2extra 
g ego_comment_mon2 = ego_comment_mon * ego_comment_mon
g ego_posttag_mon2 = ego_posttag_mon * ego_posttag_mon

g d1_comment_mon_mean2 = d1_comment_mon_mean * d1_comment_mon_mean
g d1_posttag_mon_mean2 = d1_posttag_mon_mean * d1_posttag_mon_mean

g d2_comment_mon2 = d2_comment_mon * d2_comment_mon
g d2_posttag_mon2 = d2_posttag_mon * d2_posttag_mon

g ego_density2 = ego_density * ego_density
g d2_density2 = d2_density * d2_density
g d1_density_mean2 = d1_density_mean * d1_density_mean

g egolcc_d2tag = ego_density * d2_posttag_mon

* lcc interaction
g ego_d2_lcc = ego_density * d2_density
g ego_d1_lcc = ego_density * d1_density_mean 
g d2_d1_lcc = d1_density_mean * d2_density


*xtile
*drop ego_density_q d2_density_q d1_density_mean_q
xtile ego_density_q = ego_density, nq(5)
xtile d2_density_q = d2_density, nq(5)
xtile d1_density_mean_q = d1_density_mean, nq(5)

****************label
*lcc
label var egolcc_d2tag "ego's lcc # degree-2 alter tagged"
label var d2_d1_lcc "degree-2 alter lcc # degree-1 alter lcc"
label var ego_d1_lcc "ego lcc # degree-1 alter lcc"
label var ego_d2_lcc "ego lcc # degree-2 alter lcc"
label var d2_alterid "degree-2 alterid"
*deg
label var d2_deg "degree-2 alter's degree"
label var ego_deg "ego's degree"
*C1 label
label var egoextra "ego's extroversion"
label var egofemale "ego's gender (1=female)"
label var egoeduyr "ego years of education"
label var egoage "ego's age"
label var egoextra2 "ego's extroversion^2"
*C2 label (ego online)
label var ego_fbday "ego total days on FB"
label var ego_fbday100 "ego total days on FB(/100days)"
label var egoage_fb100 "interaction: age and total days"
label var ego_density "ego's lcc"
label var ego_comment1 "ego commented"
label var ego_comment_mon "ego commented per month"
label var ego_comment_mon2 "ego commented per month^2"
label var ego_posttag1 "ego was tagged"
label var ego_posttag_mon "ego tagged"
label var ego_posttag_mon2 "ego tagged per month^2"
*c3 label (d1 online action)
label var d1extra_mean "d1 extroversion"
label var d1female_mean "d1 female (1=female)"
label var d1age_mean "d1 age"
label var d1extra_mean2 "d1extra^2"
label var d1_tieego_mean100 "d1 duration of tie with ego"
label var d1_neighbor_mean_1 "d1's neighbor"
label var d1_neighbor_mean_2 "d1's neighbor^2"
label var d1_density_mean "d1's local clustering coefficient"
label var d1_comment_mean1 "d1 commented"
label var d1_comment_mon_mean "d1 commented per month"
label var d1_comment_mon_mean2 "d1 commented per month^2"
label var d1_posttag_mean1 "d1 was tagged"
label var d1_posttag_mon_mean "d1 tagged per month"
label var d1_posttag_mon_mean2 "d1 tagged per month^2"
*C4 label (d2)
label var d2extra "degree-2 alter's extroversion"
label var d2female "degree-2 alter's gender (1=female)"
label var d2age "degree-2 alter's age"
label var d2extra2 "degree-2 alter's extra^2"
label var d2_contactppl "mutual neighbor"
label var d2_comment1 "d2 commented"
label var d2_comment_mon "d2 commented per month"
label var d2_comment_mon2 "d2 commented per month^2"
label var d2_posttag1 "d2 was tagged"
label var d2_posttag_mon "degree-2 alter tagged"
label var d2_posttag_mon2 "degree-2 alter tagged^2"
label var d2_density "degree-2 alter lcc"
*other
label var d2firstday "alter became d2_alter"
label var transfer "whether d2 transfer to d1 or not"
label var eventover "20160630(or when d2 trans)"
label var duration "survival duration(d2 firstime to eventover)"
label define TRANSFER 1"trans" 0"no trans"
label value transfer TRANSFER
label define EGOFEMALE 1"female" 0"male"
label value egofemale EGOFEMALE
label define TRANS_TYPE 0"no trans" 1"d2 initiated" 2"ego initiated"
label value trans_type TRANS_TYPE

* add d2_density, drop posttag

g ego_d2_comment = ego_comment_mon * d2_comment_mon
g ego2_d2_lcc = ego_density2 * d2_density
g ego_d22_lcc = ego_density * d2_density2
g ego_d2_lcc_2 = ego_density2 * d2_density2
* survey is control variable
global egosurvey egoextra egofemale egoage d2_contactppl degree
global d2survey d2extra d2female d2age
global egofb ego_posttag_mon 
global d2fb d2_posttag_mon
global lcc ego_density d2_density ego_d2_lcc
global control egoextra egofemale egoage d2female d2age d2extra d2_contactppl ego_deg d2_deg
global allvar transfer duration $control $lcc $egofb $d2fb



summarize ego_posttag_mon, detail
* set picture stype
set scheme s1color

***********survival model
preserve
replace transfer = 0 if trans_type == 1
stset duration, failure(transfer==1)
*sts test c.ego_density#c.d2_posttag_mon
*sts test c.ego_density#c.d2_posttag_mon ,logrank
sts test egofemale ,logrank

eststo model1: quietly mestreg $control $lcc || ego_id:, dist(exponential)
estat phtest
eststo model2: quietly mestreg $control $lcc $egofb $d2fb || ego_id:, dist(exponential)
estat phtest
eststo model3: quietly mestreg $control $lcc $egofb $d2fb c.ego_density#c.d2_posttag_mon || ego_id:, dist(exponential)
estat phtest
 margins, predict(median) at (d2_posttag_mon=(0(1)7) ego_density=(0 0.25 0.5 0.75 1))

quietly margins, at (d2_posttag_mon=(0(1)7) ego_density=(0 0.25 0.5 0.75 1))
marginsplot, legend(pos(3) cols(1) subtitle("ego's lcc",size(*.75)) symxsize(*0.75) rowgap(0.1) size(small) order(1 "0" 2 "0.25" 3 "0.5" 4 "0.75" 5 "1")) recast(line) noci plot1opts(lcolor(gs13)) plot2opts(lcolor(gs10)) plot3opts(lcolor(gs7)) plot4opts(lcolor(gs4)) plot5opts(lcolor(gs1)) title("Degree-2 alter tagged # ego's lcc (ego initiated)",size(*0.75))
raph export "../outcome/`outDate'/egod2/egoinit_d2tagegolcc.png",replace
quietly margins, at (d2_density=(0(0.2)1) ego_density=(0 0.25 0.5 0.75 1))
marginsplot, legend(pos(3) cols(1) subtitle("ego's lcc",size(*.75)) symxsize(*0.75) rowgap(0.1) size(small) order(1 "0" 2 "0.25" 3 "0.5" 4 "0.75" 5 "1")) recast(line) noci plot1opts(lcolor(gs13)) plot2opts(lcolor(gs10)) plot3opts(lcolor(gs7)) plot4opts(lcolor(gs4)) plot5opts(lcolor(gs1)) title("Degree-2 alter's lcc  # ego's lcc (ego initiated)",size(*0.75))
graph export "../outcome/`outDate'/egod2/egoinit_egod2lcc.png",replace
restore

preserve
replace transfer = 0 if trans_type == 2
stset duration, failure(transfer==1)
eststo model4: quietly mestreg $control $lcc || ego_id:, dist(exponential)
estat phtest
eststo model5: quietly mestreg $control $lcc $egofb $d2fb || ego_id:, dist(exponential)
estat phtest
eststo model6: quietly mestreg $control $lcc $egofb $d2fb c.ego_density#c.d2_posttag_mon || ego_id:, dist(exponential)
estat phtest
margins, predict(hazard) at (d2_posttag_mon=(0(1)7) ego_density=(0 0.25 0.5 0.75 1))

quietly margins, at (d2_posttag_mon=(0(1)7) ego_density=(0 0.25 0.5 0.75 1))
marginsplot, legend(pos(3) cols(1) subtitle("ego's lcc",size(*.75)) symxsize(*0.75) rowgap(0.1) size(small) order(1 "0" 2 "0.25" 3 "0.5" 4 "0.75" 5 "1")) recast(line) noci plot1opts(lcolor(gs13)) plot2opts(lcolor(gs10)) plot3opts(lcolor(gs7)) plot4opts(lcolor(gs4)) plot5opts(lcolor(gs1)) title("Degee-2 alter tagged # ego's lcc (degree-2 alter initiated)",size(*0.75))
graph export "../outcome/`outDate'/egod2/d2init_d2tagegolcc.png",replace
*SET MIN AT 17 AND MAX 24
quietly margins, at (d2_density=(0(0.2)1) ego_density=(0 0.25 0.5 0.75 1))
marginsplot, legend(pos(3) cols(1) subtitle("ego's lcc",size(*.75)) symxsize(*0.75) rowgap(0.1) size(small) order(1 "0" 2 "0.25" 3 "0.5" 4 "0.75" 5 "1")) recast(line) noci plot1opts(lcolor(gs13)) plot2opts(lcolor(gs10)) plot3opts(lcolor(gs7)) plot4opts(lcolor(gs4)) plot5opts(lcolor(gs1)) title("Degee-2 alter's lcc # ego's lcc (degree-2 alter initiated)",size(*0.75))
*marginsplot, ylab(15(1)20) recast(line) noci scheme(s1color)
graph export "../outcome/`outDate'/egod2/d2init_egod2lcc.png",replace
esttab model1 model2 model3 model4 model5 model6, eform replace cells(b(star fmt(3) label(Coef.)) se(par fmt(3) label(std.errors))) starlevels(* 0.10 ** 0.05 *** 0.010) stats(N, labels ("No. of Obs.") fmt(0)) label
restore
esttab model1 model2 model3 model4 model5 model6 using "../outcome/`outDate'/egod2/d2survival_lcc_`outDate'.rtf",eform replace cells(b(star fmt(3) label(Coef.)) se(par fmt(3) label(std.errors))) starlevels(* 0.10 ** 0.05 *** 0.010) stats(N, labels ("No. of Obs.") fmt(0)) label


* write summary table
preserve
rename ($allvar) _=
gen long obs_no = _n
reshape long _, i(obs_no) j(variable) string
asdoc table variable trans_type, col format(%6.3f) c(mean _ sd _) save(../outcome/`outDate'/egod2/d2sum.doc) replace
restore


*stcurve, survival at (c.d2_posttag_mon##c.ego_density)
*stcurve, survival at (c.d2_posttag_mon=(0(1)7) c.ego_density=(0 0.25 0.5 0.75 1))
*margins median, at (d2_posttag_mon=(0(1)7) ego_density=(0 0.25 0.5 0.75 1)) predict(median)
*margins, d2_posttag_mon#ego_density

