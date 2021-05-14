data data;
      input cid bal per;
      datalines;
1 11 1
1 12 2
1 13 3
1 14 4
1 15 5
1 16 6
1 17 7
1 18 8
1 19 9
1 20 10
1 21 11
1 22 12
2 23 1
2 24 2
2 25 3
2 26 4
2 27 5
2 28 6
2 29 7

2 31 9
2 32 10
2 33 11
2 34 12
;
run;

data df;
      set data;

      l1per = per - 1;
      l2per = per - 2;
      l3per = per - 3;
      l4per = per - 4;
      l5per = per - 5;
	  l6per = per - 6;
run; 

/* Waterfall Generator for Timeframe Derivation */
%macro vars(dsn,chr,out);                                   
      %let dsid=%sysfunc(open(&dsn));
      %let n=%sysfunc(attrn(&dsid,nvars));
      data &out;
            set &dsn(rename=(
            %do i=1 %to &n;
                  %let var=%sysfunc(varname(&dsid,&i));
                  &var=&chr&var
            %end;));
            %let rc=%sysfunc(close(&dsid));
      run;
%mend vars;

%vars(df,l1_,df1);
%vars(df,l2_,df2);
%vars(df,l3_,df3);
%vars(df,l4_,df4);
%vars(df,l5_,df5);
%vars(df,l6_,df6);



proc sql;
	create table df_new as
		select a.*,b.l1_bal,c.l2_bal,d.l3_bal,e.l4_bal,f.l5_bal,g.l6_bal
		from df a 

		left join df1 b
      	on a.cid=b.l1_cid and a.l1per=b.l1_per

		left join df2 c
      	on a.cid=c.l2_cid and a.l2per=c.l2_per

		left join df3 d
      	on a.cid=d.l3_cid and a.l3per=d.l3_per

		left join df4 e
      	on a.cid=e.l4_cid and a.l4per=e.l4_per

		left join df5 f
      	on a.cid=f.l5_cid and a.l5per=f.l5_per

		left join df6 g
      	on a.cid=g.l6_cid and a.l6per=g.l6_per;
run; quit; 
data df_final;
      set df_new;

      last6bal = sum(bal,l1_bal,l2_bal,l3_bal,l4_bal,l5_bal);
      drop l1per l2per l3per l4per l5per;
run;


proc sql;
	create table step3 as
	select *, sum(maxbal,last2bal) as having
	from (
	select a.*,
			MAX(bal) as maxbal,
			SUM(l1_bal,l2_bal) as last2bal
		from df_final a )
		group by cid
		order by cid;
run; quit;


