#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# module for preparing Income Statement and Balance Sheet
# 
#======================================================================

require "$form->{path}/arap.pl";

use SL::PE;
use SL::RP;

1;
# end of main

# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')

# $locale->text('Balance Sheet')
# $locale->text('Income Statement')
# $locale->text('Trial Balance')
# $locale->text('AR Aging')
# $locale->text('AP Aging')
# $locale->text('Tax collected')
# $locale->text('Tax paid')
# $locale->text('Receipts')
# $locale->text('Payments')
# $locale->text('Project Transactions')
# $locale->text('Non-taxable Sales')
# $locale->text('Non-taxable Purchases')


sub report {

  $form->{decimalplaces} = $form->{precision};

  %report = ( balance_sheet	=> { title => 'Balance Sheet' },
             income_statement	=> { title => 'Income Statement' },
             trial_balance	=> { title => 'Trial Balance' },
	     ar_aging		=> { title => 'AR Aging', vc => 'customer' },
	     ap_aging		=> { title => 'AP Aging', vc => 'vendor' },
	     tax_collected	=> { title => 'Tax collected', vc => 'customer' },
	     tax_paid		=> { title => 'Tax paid' },
	     nontaxable_sales	=> { title => 'Non-taxable Sales', vc => 'customer' },
	     nontaxable_purchases => { title => 'Non-taxable Purchases' },
	     receipts		=> { title => 'Receipts', vc => 'customer' },
	     payments		=> { title => 'Payments' },
	     projects		=> { title => 'Project Transactions' },
	   );
  
  $form->{title} = $locale->text($report{$form->{report}}->{title});

  $gifi = qq|
<tr>
  <th align=right>|.$locale->text('Accounts').qq|</th>
  <td><input name=accounttype class=radio type=radio value=standard checked> |.$locale->text('Standard').qq|
   
      <input name=accounttype class=radio type=radio value=gifi> |.$locale->text('GIFI').qq|
  </td>
</tr>
|;
  
    
  # get departments
  $form->all_departments(\%myconfig, undef, $report{$form->{report}}->{vc});
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "<option>\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="|.$form->quote($_->{description}).qq|--$_->{id}">$_->{description}\n| }
  }
 
  $department = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
| if $form->{selectdepartment};

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "<option>\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }
    $selectaccountingmonth = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	  <select name=month>$selectaccountingmonth</select>
	  <select name=year>$selectaccountingyear</select>
	  <input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	  <input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	  <input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	  <input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	  </td>
	</tr>
|;

    $selectto = qq|
        <tr>
	  <th align=right></th>
	  <td>
	  <select name=month>$selectaccountingmonth</select>
	  <select name=year>$selectaccountingyear</select>
	  </td>
	</tr>
|;
  }


  $summary = qq|
	<tr>
	  <th></th>
	  <td><input name=summary type=radio class=radio value=1 checked> |.$locale->text('Summary').qq|
	  <input name=summary type=radio class=radio value=0> |.$locale->text('Detail').qq|
	  </td>
	</tr>
|;

  # get projects
  $form->all_projects(\%myconfig);
  if (@{ $form->{all_project} }) {
    $form->{selectproject} = "<option>\n";
    for (@{ $form->{all_project} }) { $form->{selectproject} .= qq|<option value="|.$form->quote($_->{projectnumber}).qq|--$_->{id}">$_->{projectnumber}\n| }

    $project = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Project').qq|</th>
	  <td colspan=3><select name=projectnumber>$form->{selectproject}</select></td>
	</tr>|;

  }
  
  $method{accrual} = "checked" if $form->{method} eq 'accrual';
  $method{cash} = "checked" if $form->{method} eq 'cash';

  $method = qq|
	<tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td colspan=3><input name=method class=radio type=radio value=accrual $method{accrual}>&nbsp;|.$locale->text('Accrual').qq|
	  &nbsp;<input name=method class=radio type=radio value=cash $method{cash}>&nbsp;|.$locale->text('Cash').qq|</td>
	</tr>
|;


  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
      $department
|;

  if ($form->{report} eq "projects") {
    $form->{nextsub} = "generate_projects";
    
    print qq|
        $project
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|</td>
	</tr>
|;
  }

  if ($form->{report} eq "income_statement") {
    $form->{nextsub} = "generate_income_statement";
    
    print qq|
	$project
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
|;

    if ($selectfrom) {
      print qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	  <select name=frommonth>$selectaccountingmonth</select>
	  <select name=fromyear>$selectaccountingyear</select>
	  <input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	  <input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	  <input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	  <input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	  </td>
	</tr>
|;
    }

    print qq|

	<tr>
	  <th align=right>|.$locale->text('Compare to').qq|</th>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=comparefromdate size=11 title="$myconfig{dateformat}"> <b>|.$locale->text('To').qq|</b> <input name=comparetodate size=11 title="$myconfig{dateformat}"></td>
	</tr>
|;

    if ($selectto) {
      print qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td>
	  <select name=comparemonth>$selectaccountingmonth</select>
	  <select name=compareyear>$selectaccountingyear</select>
	  </td>
	</tr>
|;
    }

    print qq|
	<tr>
	  <th align=right>|.$locale->text('Decimalplaces').qq|</th>
	  <td><input name=decimalplaces size=3 value=$form->{decimalplaces}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        $method

	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
	  <input name=l_accno class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Account Number').qq|</td>
	</tr>
|;
  }


  if ($form->{report} eq "balance_sheet") {
    $form->{nextsub} = "generate_balance_sheet";
    
    print qq|
	<tr>
	  <th align=right>|.$locale->text('as at').qq|</th>
	  <td><input name=asofdate size=11 title="$myconfig{dateformat}" value=$form->{asofdate}></td>
|;

   if ($selectfrom) {
     print qq|
	  <td>
	  <select name=asofmonth>$selectaccountingmonth</select>
	  <select name=asofyear>$selectaccountingyear</select>
	  </td>
|;
   }

   print qq|
	</tr>

	  <th align=right nowrap>|.$locale->text('Compare to').qq|</th>
	  <td><input name=compareasofdate size=11 title="$myconfig{dateformat}"></td>
	  <td>
|;

   if ($selectto) {
     print qq|
	  <select name=compareasofmonth>$selectaccountingmonth</select>
	  <select name=compareasofyear>$selectaccountingyear</select>
	  </td>
|;
   }

   print qq|
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Decimalplaces').qq|</th>
	  <td><input name=decimalplaces size=3 value=2></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        $method

	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
	  <input name=l_accno class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Account Number').qq|</td>
	</tr>
|;
  }


  if ($form->{report} eq "trial_balance") {
    $form->{nextsub} = "generate_trial_balance";
    
    print qq|
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
	  <input name=all_accounts class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('All Accounts').qq|</td>
	</tr>
|;
  }

  
  if ($form->{report} =~ /^tax_/) {
    $gifi = "";

    $form->{db} = ($form->{report} =~ /_collected/) ? "ar" : "ap";
    
    RP->get_taxaccounts(\%myconfig, \%$form);

    $form->{nextsub} = "generate_tax_report";
    
    print qq|
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$summary
	<tr>
	  <th align=right>|.$locale->text('Report for').qq|</th>
	  <td colspan=3>
|;

  $checked = "checked";
  foreach $ref (@{ $form->{taxaccounts} }) {
    
    print qq|<input name=accno class=radio type=radio value="|.$form->quote($ref->{accno}).qq|" $checked>&nbsp;$ref->{description}

    <input name="$ref->{accno}_description" type=hidden value="|.$form->quote($ref->{description}).qq|">|;

    $checked = "";

  }

  print qq|
<input type=hidden name=db value=$form->{db}>
<input type=hidden name=sort value=transdate>

	  </td>
	</tr>
|;


  if (@{ $form->{gifi_taxaccounts} }) {
    print qq|
        <tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>
	  <td colspan=3>
|;

    foreach $ref (@{ $form->{gifi_taxaccounts} }) {
      
      print qq|<input name=accno class=radio type=radio value="|.$form->quote("gifi_$ref->{accno}").qq|">&nbsp;$ref->{description}

      <input name="gifi_$ref->{accno}_description" type=hidden value="|.$form->quote($ref->{description}).qq|">|;

    }

    print qq|
	  </td>
	</tr>
|;
  }

  if ($form->{db} eq 'ar') {
    $vc = qq|
    <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
    <td>|.$locale->text('Customer').qq|</td>
    <td><input name="l_customernumber" class=checkbox type=checkbox value=Y></td>
    <td>|.$locale->text('Customer Number').qq|</td>|;
  }
  
  if ($form->{db} eq 'ap') {
    $vc = qq|
    <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
    <td>|.$locale->text('Vendor').qq|</td>
    <td><input name="l_vendornumber" class=checkbox type=checkbox value=Y></td>
    <td>|.$locale->text('Vendor Number').qq|</td>|;
  }
  

print qq|
        $method
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name="l_id" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('ID').qq|</td>
		<td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Invoice').qq|</td>
		<td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Date').qq|</td>
  	        <td><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Description').qq|</td>
	      </tr>
	      
	      <tr>
	        $vc
	      
		<td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Amount').qq|</td>
		
		<td><input name="l_tax" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Tax').qq|</td>
		
	      </tr>
	      <tr>
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  }

  
  if ($form->{report} =~ /^nontaxable_/) {
    $gifi = "";

    $form->{db} = ($form->{report} =~ /_sales/) ? "ar" : "ap";

    $form->{nextsub} = "generate_tax_report";

    if ($form->{db} eq 'ar') {
      $vc = qq|
      <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
      <td>|.$locale->text('Customer').qq|</td>
      <td><input name="l_customernumber" class=checkbox type=checkbox value=Y></td>
      <td>|.$locale->text('Customer Number').qq|</td>|;
    }
    
    if ($form->{db} eq 'ap') {
      $vc = qq|
      <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
      <td>|.$locale->text('Vendor').qq|</td>
      <td><input name="l_vendornumber" class=checkbox type=checkbox value=Y></td>
      <td>|.$locale->text('Vendor Number').qq|</td>|;
    }
   
  
    print qq|

        <input type=hidden name=db value=$form->{db}>
        <input type=hidden name=sort value=transdate>
        <input type=hidden name=report value=$form->{report}>

	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$summary
	$method
        <tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
		<td><input name="l_id" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('ID').qq|</td>
		<td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Invoice').qq|</td>
		<td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Date').qq|</td>
	        <td><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Description').qq|</td>
	      </tr>
	      <tr>

	        $vc

                <td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Amount').qq|</td>
	      </tr>
	      <tr>
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  }


  if (($form->{report} eq "ar_aging") || ($form->{report} eq "ap_aging")) {
    $gifi = "";

    if ($form->{report} eq 'ar_aging') {
      $vclabel = $locale->text('Customer');
      $vcnumber = $locale->text('Customer Number');
      $form->{vc} = 'customer';
    } else {
      $vclabel = $locale->text('Vendor');
      $vcnumber = $locale->text('Vendor Number');
      $form->{vc} = 'vendor';
    }
      
    $form->{nextsub} = "generate_$form->{report}";

    $form->{type} = "statement";
    $form->{format} ||= $myconfig{outputformat};
    $form->{media} ||= $myconfig{printer};
    
    # setup vc selection
    $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP");

    if ($@{ $form->{"all_$form->{vc}"} }) {
      $vc = qq|
           <tr>
	     <th align=right nowrap>$vclabel</th>
	     <td colspan=2><select name=$form->{vc}><option>\n|;
	     
      for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $vc .= qq|</select>
             </td>
	   </tr>
|;
    } else {
      $vc = qq|
                <tr>
		  <th align=right nowrap>$vclabel</th>
		  <td colspan=2><input name=$form->{vc} size=35>
		  </td>
		</tr>
		<tr>
		  <th align=right nowrap>$vcnumber</th>
		  <td colspan=3><input name="$form->{vc}number" size=35>
		  </td>
		</tr>
|;
    }
		  
    print qq|
        $vc
	<tr>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectto
	<input type=hidden name=action value="$form->{nextsub}">
	$summary
	<tr>
	  <table>
	    <tr>
	      <th>|.$locale->text('Include in Report').qq|</th>

	      <td>
	        <table>
		  <tr>
	            <td nowrap><input name=overdue type=radio class=radio value=0 checked> |.$locale->text('Aged').qq|</td>
 	            <td nowrap><input name=overdue type=radio class=radio value=1> |.$locale->text('Overdue').qq|</td>
	          </tr>
		  <tr>
		    <td nowrap width=70><input name=c0 type=checkbox class=checkbox value=1 checked> |.$locale->text('Current').qq|</td>
		    <td nowrap width=70><input name=c30 type=checkbox class=checkbox value=1 checked> 30</td>
		    <td nowrap width=70><input name=c60 type=checkbox class=checkbox value=1 checked> 60</td>
		    <td nowrap width=70><input name=c90 type=checkbox class=checkbox value=1 checked> 90</td>
		  </tr>
		  <tr>
		    <td nowrap width=70><input name=c15 type=checkbox class=checkbox value=1> 15</td>
		    <td nowrap width=70><input name=c45 type=checkbox class=checkbox value=1> 45</td>
		    <td nowrap width=70><input name=c75 type=checkbox class=checkbox value=1> 75</td>
		  </tr>
		</table>
	      </td>
	    </tr>
	  </table>
	</tr>

|;

    $form->hide_form(qw(nextsub type format media));

  }

# above action can be removed if there is more than one input field


  if ($form->{report} =~ /(receipts|payments)$/) {
    
    $form->{nextsub} = "list_payments";

    $gifi = "";

    $form->{db} = ($form->{report} =~ /payments/) ? "ap" : "ar";
    $form->{vc} = ($form->{db} eq 'ar') ? 'customer' : 'vendor';

    RP->paymentaccounts(\%myconfig, \%$form);

    $selectpaymentaccount = "\n";
    foreach $ref (@{ $form->{PR} }) {
      $form->{paymentaccounts} .= "$ref->{accno} ";
      $selectpaymentaccount .= qq|$ref->{accno}--$ref->{description}\n|;
    }
    
    chop $form->{paymentaccounts};

    $form->hide_form(qw(paymentaccounts));
   
    if ($form->{vc} eq 'customer') {
      $vclabel = $locale->text('Customer');
      $vcnumber = $locale->text('Customer Number');
      $form->all_vc(\%myconfig, $form->{vc}, "AR");
    } else {
      $form->all_vc(\%myconfig, $form->{vc}, "AP");
      $vclabel = $locale->text('Vendor');
      $vcnumber = $locale->text('Vendor Number');
    }
 
    # setup vc selection
    if ($@{ $form->{"all_$form->{vc}"} }) {
      $vc = qq|
           <tr>
	     <th align=right nowrap>$vclabel</th>
	     <td colspan=2><select name=$form->{vc}><option>\n|;

      for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $vc .= qq|</select>
             </td>
	   </tr>
|;
    } else {
      $vc = qq|
                <tr>
		  <th align=right nowrap>$vclabel</th>
		  <td colspan=2><input name=$form->{vc} size=35>
		  </td>
		</tr>
		<tr>
		  <th align=right nowrap>$vcnumber</th>
		  <td colspan=3><input name="$form->{vc}number" size=35>
		  </td>
		</tr>
|;
    }

    print qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
          <td colspan=3><select name=account>|
	  .$form->select_option($selectpaymentaccount)
	  .qq|</select>
	  </td>
	</tr>
	$vc
        <tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=35></td>
	</tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Source').qq|</th>
          <td colspan=3><input name=source></td>
	</tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Memo').qq|</th>
          <td colspan=3><input name=memo size=30></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table width=100%>
	      <tr>
		<td align=right><input type=checkbox class=checkbox name=fx_transaction value=1 checked> |.$locale->text('Exchange Rate Difference').qq|</td>
	      </tr>
|;

    @a = ();
    
    push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date');
    push @a, qq|<input name="l_reference" class=checkbox type=checkbox value=Y checked> |.$locale->text('Reference');
    push @a, qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> |.$locale->text($vclabel);
    push @a, qq|<input name="l_$form->{vc}number" class=checkbox type=checkbox value=Y> |.$locale->text($vcnumber);
    push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
    push @a, qq|<input name="l_paid" class=checkbox type=checkbox value=Y checked> |.$locale->text('Amount');
    push @a, qq|<input name="l_source" class=checkbox type=checkbox value=Y checked> |.$locale->text('Source');
    push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y checked> |.$locale->text('Memo');
    
    while (@a) {
      for (1 .. 5) {
	print qq|<td nowrap>|. shift @a;
	print qq|</td>\n|;
      }
      print qq|</tr>\n|;
    }

    print qq|
	      <tr>
		<td><input name=l_subtotal class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

    $form->{sort} = 'transdate';
    $form->hide_form(qw(vc db sort));

  }


  print qq|

      $gifi

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->hide_form(qw(title nextsub path login));

  print qq|

</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub continue { &{$form->{nextsub}} };


sub generate_income_statement {

  $form->{padding} = "&nbsp;&nbsp;";
  $form->{bold} = "<strong>";
  $form->{endbold} = "</strong>";
  $form->{br} = "<br>";
  
  RP->income_statement(\%myconfig, \%$form);

  ($form->{department}) = split /--/, $form->{department};
  ($form->{projectnumber}) = split /--/, $form->{projectnumber};
  
  $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  $form->{todate} = $form->current_date(\%myconfig) unless $form->{todate};

  # if there are any dates construct a where
  if ($form->{fromdate} || $form->{todate}) {
    
    unless ($form->{todate}) {
      $form->{todate} = $form->current_date(\%myconfig);
    }

    $longtodate = $locale->date(\%myconfig, $form->{todate}, 1);
    $shorttodate = $locale->date(\%myconfig, $form->{todate}, 0);
    
    $longfromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    $shortfromdate = $locale->date(\%myconfig, $form->{fromdate}, 0);
    
    $form->{this_period} = "$shortfromdate<br>\n$shorttodate";
    $form->{period} = $locale->text('for Period').qq|<br>\n$longfromdate |.$locale->text('To').qq| $longtodate|;
  }

  if ($form->{comparefromdate} || $form->{comparetodate}) {
    $longcomparefromdate = $locale->date(\%myconfig, $form->{comparefromdate}, 1);
    $shortcomparefromdate = $locale->date(\%myconfig, $form->{comparefromdate}, 0);
    
    $longcomparetodate = $locale->date(\%myconfig, $form->{comparetodate}, 1);
    $shortcomparetodate = $locale->date(\%myconfig, $form->{comparetodate}, 0);
    
    $form->{last_period} = "$shortcomparefromdate<br>\n$shortcomparetodate";
    $form->{period} .= "<br>\n$longcomparefromdate ".$locale->text('To').qq| $longcomparetodate|;
  }

  # setup variables for the form
  $form->format_string(qw(company address businessnumber));
  $form->{address} =~ s/\n/<br>/g;

  $form->{templates} = $myconfig{templates};

  $form->{IN} = "income_statement.html";
  
  $form->parse_template;

}


sub generate_balance_sheet {

  $form->{padding} = "&nbsp;&nbsp;";
  $form->{bold} = "<b>";
  $form->{endbold} = "</b>";
  $form->{br} = "<br>";
  
  RP->balance_sheet(\%myconfig, \%$form);

  $form->{asofdate} = $form->current_date(\%myconfig) unless $form->{asofdate};
  $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  
  ($form->{department}) = split /--/, $form->{department};
  
  # define Current Earnings account
  $padding = ($form->{l_heading}) ? $form->{padding} : "";
  push(@{$form->{equity_account}}, $padding.$locale->text('Current Earnings'));

  $form->{this_period} = $locale->date(\%myconfig, $form->{asofdate}, 0);
  $form->{last_period} = $locale->date(\%myconfig, $form->{compareasofdate}, 0);

  $form->{IN} = "balance_sheet.html";

  # setup company variables for the form
  $form->format_string(qw(company address businessnumber));
  $form->{address} =~ s/\n/<br>/g;

  $form->{templates} = $myconfig{templates};
	  
  $form->parse_template;

}


sub generate_projects {

  $form->{nextsub} = "generate_projects";
  $form->{title} = $locale->text('Project Transactions');

  RP->trial_balance(\%myconfig, \%$form);
  
  &list_accounts;

}


# Antonio Gallardo
#
# D.S. Feb 16, 2001
# included links to display transactions for period entered
# added headers and subtotals
#
sub generate_trial_balance {

  # get for each account initial balance, debits and credits
  RP->trial_balance(\%myconfig, \%$form);

  $form->{nextsub} = "generate_trial_balance";
  $form->{title} = $locale->text('Trial Balance');

  $form->{callback} = "$form->{script}?action=generate_trial_balance";
  for (qw(login path nextsub fromdate todate month year interval l_heading l_subtotal all_accounts accounttype)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(department title)) { $form->{callback} .= "&$_=".$form->escape($form->{$_},1) }

  $form->{callback} = $form->escape($form->{callback});
  
  &list_accounts;

}


sub list_accounts {

  $title = $form->escape($form->{title});
  
  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $options = $locale->text('Department')." : $department<br>";
    $department = $form->escape($form->{department});
  }
  if ($form->{projectnumber}) {
    ($projectnumber) = split /--/, $form->{projectnumber};
    $options .= $locale->text('Project Number')." : $projectnumber<br>";
    $projectnumber = $form->escape($form->{projectnumber});
  }

  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {

    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);

  }
  $options .= $form->{period};

  @column_index = qw(accno description begbalance debit credit endbalance);

  $column_header{accno} = qq|<th class=listheading width=10%>|.$locale->text('Account').qq|</th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{debit} = qq|<th class=listheading width=10%>|.$locale->text('Debit').qq|</th>|;
  $column_header{credit} = qq|<th class=listheading width=10%>|.$locale->text('Credit').qq|</th>|;
  $column_header{begbalance} = qq|<th class=listheading width=10%>|.$locale->text('Beginning Balance').qq|</th>|;
  $column_header{endbalance} = qq|<th class=listheading width=10%>|.$locale->text('Ending Balance').qq|</th>|;


  if ($form->{accounttype} eq 'gifi') {
    $column_header{accno} = qq|<th class=listheading>|.$locale->text('GIFI').qq|</th>|;
  }
  

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$options</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr>|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;


  
  # sort the whole thing by account numbers and display
  foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{TB} }) {

    $description = $form->escape($ref->{description});
    
    $href = qq|ca.pl?path=$form->{path}&action=list_transactions&accounttype=$form->{accounttype}&login=$form->{login}&fromdate=$form->{fromdate}&todate=$form->{todate}&sort=transdate&l_heading=$form->{l_heading}&l_subtotal=$form->{l_subtotal}&department=$department&projectnumber=$projectnumber&project_id=$form->{project_id}&title=$title&nextsub=$form->{nextsub}&prevreport=$form->{callback}|;
    
    if ($form->{accounttype} eq 'gifi') {
      $href .= "&gifi_accno=$ref->{accno}&gifi_description=$description";
      $na = $locale->text('N/A');
      if (!$ref->{accno}) {
	for (qw(accno description)) { $ref->{$_} = $na }
      }
    } else {
      $href .= "&accno=$ref->{accno}&description=$description";
    }

    $ml = ($ref->{category} =~ /(A|E)/) ? -1 : 1;
    $ml *= -1 if $ref->{contra};
    
    $debit = $form->format_amount(\%myconfig, $ref->{debit}, $form->{precision}, "&nbsp;");
    $credit = $form->format_amount(\%myconfig, $ref->{credit}, $form->{precision}, "&nbsp;");
    $begbalance = $form->format_amount(\%myconfig, $ref->{balance} * $ml, $form->{precision}, "&nbsp;");
    $endbalance = $form->format_amount(\%myconfig, ($ref->{balance} + $ref->{amount}) * $ml, $form->{precision}, "&nbsp;");

 
    if ($ref->{charttype} eq "H" && $subtotal && $form->{l_subtotal}) {

      if ($subtotal) {

	for (qw(accno begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }

	$subtotalbegbalance = $form->format_amount(\%myconfig, $subtotalbegbalance, $form->{precision}, "&nbsp;");
	$subtotalendbalance = $form->format_amount(\%myconfig, $subtotalendbalance, $form->{precision}, "&nbsp;");
	$subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;");
	$subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;");
	
	$column_data{description} = "<th class=listsubtotal>$subtotaldescription</th>";
	$column_data{begbalance} = "<th align=right class=listsubtotal>$subtotalbegbalance</th>";
	$column_data{endbalance} = "<th align=right class=listsubtotal>$subtotalendbalance</th>";
	$column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</th>";
	$column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</th>";
	
	print qq|
	  <tr class=listsubtotal>
|;
	for (@column_index) { print "$column_data{$_}\n" }
	
	print qq|
	  </tr>
|;
      }
    }
 
    if ($ref->{charttype} eq "H") {
      $subtotal = 1;
      $subtotaldescription = $ref->{description};
      $subtotaldebit = $ref->{debit};
      $subtotalcredit = $ref->{credit};
      $subtotalbegbalance = 0;
      $subtotalendbalance = 0;

      if ($form->{l_heading}) {
	if (! $form->{all_accounts}) {
	  if (($subtotaldebit + $subtotalcredit) == 0) {
	    $subtotal = 0;
	    next;
	  }
	}
      } else {
	$subtotal = 0;
	if ($form->{all_accounts} || ($form->{l_subtotal} && (($subtotaldebit + $subtotalcredit) != 0))) {
	  $subtotal = 1;
	}
	next;
      }
      
      for (qw(accno debit credit begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }
      $column_data{description} = "<th class=listheading>$ref->{description}</th>";
    }

    if ($ref->{charttype} eq "A") {
      $column_data{accno} = "<td><a href=$href>$ref->{accno}</a></td>";
      $column_data{description} = "<td>$ref->{description}</td>";
      $column_data{debit} = "<td align=right>$debit</td>";
      $column_data{credit} = "<td align=right>$credit</td>";
      $column_data{begbalance} = "<td align=right>$begbalance</td>";
      $column_data{endbalance} = "<td align=right>$endbalance</td>";
    
      $totaldebit += $ref->{debit};
      $totalcredit += $ref->{credit};

      $cml = ($ref->{contra}) ? -1 : 1;

      $subtotalbegbalance += $ref->{balance} * $ml * $cml;
      $subtotalendbalance += ($ref->{balance} + $ref->{amount}) * $ml * $cml;

    }
 
   
    if ($ref->{charttype} eq "H") {
      print qq|
      <tr class=listheading>
|;
    }
    if ($ref->{charttype} eq "A") {
      $i++; $i %= 2;
      print qq|
      <tr class=listrow$i>
|;
    }
    
    for (@column_index) { print "$column_data{$_}\n" }
    
    print qq|
      </tr>
|;
  }


  # print last subtotal
  if ($subtotal && $form->{l_subtotal}) {
    for (qw(accno begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }
    $subtotalbegbalance = $form->format_amount(\%myconfig, $subtotalbegbalance, $form->{precision}, "&nbsp;");
    $subtotalendbalance = $form->format_amount(\%myconfig, $subtotalendbalance, $form->{precision}, "&nbsp;");
    $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;");
    $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;");
    $column_data{description} = "<th class=listsubtotal>$subtotaldescription</th>";
    $column_data{begbalance} = "<th align=right class=listsubtotal>$subtotalbegbalance</th>";
    $column_data{endbalance} = "<th align=right class=listsubtotal>$subtotalendbalance</th>";
    $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</th>";
    $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</th>";
    
    print qq|
    <tr class=listsubtotal>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    
    print qq|
    </tr>
|;
  }
  
  $totaldebit = $form->format_amount(\%myconfig, $totaldebit, $form->{precision}, "&nbsp;");
  $totalcredit = $form->format_amount(\%myconfig, $totalcredit, $form->{precision}, "&nbsp;");

  for (qw(accno description begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }
 
  $column_data{debit} = qq|<th align=right class=listtotal>$totaldebit</th>|;
  $column_data{credit} = qq|<th align=right class=listtotal>$totalcredit</th>|;
  
  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub generate_ar_aging {

  # split customer
  ($form->{customer}) = split(/--/, $form->{customer});
  $customer = $form->escape($form->{customer},1);
  $title = $form->escape($form->{title},1);
  $media = $form->escape($form->{media},1);

  $form->{vc} = "customer";
  $form->{arap} = "ar";

  RP->aging(\%myconfig, \%$form);

  $form->{callback} = qq|$form->{script}?path=$form->{path}&action=generate_ar_aging&login=$form->{login}&todate=$form->{todate}&customer=$customer&title=$title&type=$form->{type}&format=$form->{format}&media=$media&summary=$form->{summary}|;
  
  &aging;
  
}


sub generate_ap_aging {
  
  # split vendor
  ($form->{vendor}) = split(/--/, $form->{vendor});
  $vendor = $form->escape($form->{vendor},1);
  $title = $form->escape($form->{title},1);
  $media = $form->escape($form->{media},1);

  $form->{vc} = "vendor";
  $form->{arap} = "ap";
  
  RP->aging(\%myconfig, \%$form);

  $form->{callback} = qq|$form->{script}?path=$form->{path}&action=generate_ap_aging&login=$form->{login}&todate=$form->{todate}&vendor=$vendor&title=$title&type=$form->{type}&format=$form->{format}&media=$media&summary=$form->{summary}|;

  &aging;
  
}


sub aging {


  $form->header;
  
  $vcnumber = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');
  
  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_header{statement} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.forms[0].submit()"><input type=hidden name=action value="$action"></th>|;
  $column_header{vc} = qq|<th class=listheading width=60%>|.$locale->text(ucfirst $form->{vc}).qq|</th>|;
  $column_header{"$form->{vc}number"} = qq|<th class=listheading>$vcnumber</th>|;
  $column_header{language} = qq|<th class=listheading>|.$locale->text('Language').qq|</th>|;
  $column_header{invnumber} = qq|<th class=listheading>|.$locale->text('Invoice').qq|</th>|;
  $column_header{ordnumber} = qq|<th class=listheading>|.$locale->text('Order').qq|</th>|;
  $column_header{transdate} = qq|<th class=listheading nowrap>|.$locale->text('Date').qq|</th>|;
  $column_header{duedate} = qq|<th class=listheading nowrap>|.$locale->text('Due Date').qq|</th>|;
  $column_header{c0} = qq|<th class=listheading width=10% nowrap>|.$locale->text('Current').qq|</th>|;
  $column_header{c15} = qq|<th class=listheading width=10% nowrap>15</th>|;
  $column_header{c30} = qq|<th class=listheading width=10% nowrap>30</th>|;
  $column_header{c45} = qq|<th class=listheading width=10% nowrap>45</th>|;
  $column_header{c60} = qq|<th class=listheading width=10% nowrap>60</th>|;
  $column_header{c75} = qq|<th class=listheading width=10% nowrap>75</th>|;
  $column_header{c90} = qq|<th class=listheading width=10% nowrap>90</th>|;
  $column_header{total} = qq|<th class=listheading width=10% nowrap>|.$locale->text('Total').qq|</th>|;
  
  @column_index = qw(statement vc);
  push @column_index, "$form->{vc}number";

  if (@{ $form->{all_language} } && $form->{arap} eq 'ar') {
    push @column_index, "language";
    $form->{selectlanguage} = qq|\n|;

    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }
  
  if (!$form->{summary}) {
    push @column_index, qw(invnumber ordnumber transdate duedate);
  }
  
  @c = qw(c0 c15 c30 c45 c60 c75 c90);
  
  for (@c) {
    if ($form->{$_}) {
      push @column_index, $_;
      $form->{callback} .= "&$_=$form->{$_}";
    }
  }
  
  push @column_index, "total";

  $option = $locale->text('Aged');
  if ($form->{overdue}) {
    $option= $locale->text('Aged Overdue');
    $form->{callback} .= "&overdue=$form->{overdue}";
  }
  
  if ($form->{department}) {
      $option .= "\n<br>" if $option;
      ($department) = split /--/, $form->{department};
      $option .= $locale->text('Department')." : $department";
      $department = $form->escape($form->{department},1);
      $form->{callback} .= "&department=$department";
  }
    
  if ($form->{arap} eq 'ar') {
    if ($form->{customer}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{customer};
    }
  }
  if ($form->{arap} eq 'ap') {
    shift @column_index;
    if ($form->{vendor}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{vendor};
    }
  }

  $todate = $locale->date(\%myconfig, $form->{todate}, 1);
  $option .= "\n<br>" if $option;
  $option .= $locale->text('for Period')." ".$locale->text('To')." $todate";

  print qq|
<script language="JavaScript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /statement_/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.allbox.checked
    }
  }

}
// -->
</script>

<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
|;

  $vc_id = 0;
  $i = 0;
  $k = 0;
  $l = $#{ $form->{AG} };
  
  foreach $ref (@{ $form->{AG} }) {

    if ($curr ne $ref->{curr}) {
      $vc_id = 0;
      for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
      if ($curr) {

	for (@c) {
	  $column_data{$_} = qq|<th align=right>|.$form->format_amount(\%myconfig, $c{$_}{total}, $form->{precision}, "&nbsp").qq|</th>|;
	  $c{$_}{total} = 0;
	  $c{$_}{subtotal} = 0;
	}
	
	$column_data{total} = qq|<th align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp").qq|</th>|;
	
	for (qw(vc statement language)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
	print qq|
	<tr class=listtotal>
|;

	for (@column_index) { print "$column_data{$_}\n" }

	print qq|
	  </tr>
|;

	$total = 0;
 
      }
      
      $curr = $ref->{curr};
      print qq|
        <tr>
	  <td></td>
	  <th>$curr</th>
	</tr>
	
	<tr class=listheading>
|;

      for (@column_index) { print "$column_header{$_}\n" }
  
      print qq|
	</tr>
|;
    }
    
    $k++;
    
    if ($vc_id != $ref->{vc_id}) {
      $i++;

      $column_data{vc} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
      $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;
      
      if ($form->{selectlanguage}) {
	$column_data{language} = qq|<td><select name="language_code_$i">|.$form->select_option($form->{selectlanguage}, $form->{"language_code_$i"}, undef, 1).qq|</select></td>|;
      }
      
      $column_data{statement} = qq|<td><input name="statement_$i" type=checkbox class=checkbox value=1 $ref->{checked}>
      <input type=hidden name="$form->{vc}_id_$i" value=$ref->{vc_id}>
      <input type=hidden name="curr_$i" value="|.$form->quote($ref->{curr}).qq|">
      </td>|;

      $linetotal = 0;

    }

    $vc_id = $ref->{vc_id};

    for (@c) {

      $ref->{$_} = $form->round_amount($ref->{$_} / $ref->{exchangerate}, $form->{precision});

      $c{$_}{total} += $ref->{$_};
      $c{$_}{subtotal} += $ref->{$_};
      $linetotal += $ref->{$_};
      $total += $ref->{$_};

      $column_data{$_} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;").qq|</td>|;
      
    }

    $column_data{total} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, $form->{precision}, "&nbsp;").qq|</td>|;

    $href = qq|$ref->{module}.pl?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&callback=|.$form->escape($form->{callback});
    
    $column_data{invnumber} = qq|<td><a href=$href>$ref->{invnumber}</a></td>|;
    $column_data{ordnumber} = qq|<td>$ref->{ordnumber}</td>|;
    for (qw(transdate duedate)) { $column_data{$_} = qq|<td nowrap>$ref->{$_}</td>| }
    
    if (!$form->{summary}) {

      $j++; $j %= 2;
      print qq|
        <tr class=listrow$j>
|;

      for (@column_index) { print "$column_data{$_}\n" }

      print qq|
        </tr>
|;

      for (qw(vc statement language)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
      
    }
   
    # print subtotal
    if ($l > 0) {
      $nextid = ($k <= $l) ? $form->{AG}->[$k]->{vc_id} : 0;
    }

    if ($vc_id != $nextid) {
     
      for (@c) {
	$c{$_}{subtotal} = $form->format_amount(\%myconfig, $c{$_}{subtotal}, $form->{precision}, "&nbsp");
      }
      
      if ($form->{summary}) {
	for (@c) {
	  $column_data{$_} = qq|<td align=right>$c{$_}{subtotal}</th>|;
	  $c{$_}{subtotal} = 0;
	}

	$j++; $j %= 2;
	print qq|
      <tr class=listrow$j>
|;

	for (@column_index) { print "$column_data{$_}\n" }

	print qq|
      </tr>
|;

      } else {

	for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }

	for (@c) {
	  $column_data{$_} = qq|<th class=listsubtotal align=right>$c{$_}{subtotal}</th>|;
	  $c{$_}{subtotal} = 0;
	}

	# print subtotals
	print qq|
      <tr class=listsubtotal>
|;
	for (@column_index) { print "$column_data{$_}\n" }

	print qq|
      </tr>
|;

      }
    }
  }
  
  print qq|
        </tr>
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
  
  for (@c) {
    $column_data{$_} = qq|<th align=right class=listtotal>|.$form->format_amount(\%myconfig, $c{$_}{total}, $form->{precision}, "&nbsp;").qq|</th>|;
  }
    
  $column_data{total} = qq|<th align=right class=listtotal>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;").qq|</th>|;

  for (@column_index) { print "$column_data{$_}\n" }
  
  print qq|
	</tr>
	<input type=hidden name=rowcount value=$i>
      </table>
    </td>
  </tr>

  <tr>
    <td>
|;

  &print_options if ($form->{arap} eq 'ar');

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  if ($form->{arap} eq 'ar') {

    $form->hide_form(qw(todate title summary overdue callback arap vc department path login));
    $form->hide_form(@c, "$form->{vc}");
    
    %button = ('Select all' => { ndx => 1, key => 'A', value => $locale->text('Select all') },
               'Deselect all' => { ndx => 2, key => 'A', value => $locale->text('Deselect all') },
               'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	       'E-mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
	      );
    
    if ($form->{deselect}) {
      delete $button{'Select all'};
    } else {
      delete $button{'Deselect all'};
    }

    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub select_all {

  RP->aging(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $_->{checked} = "checked" }
  $form->{allbox} = "checked";
  $form->{deselect} = 1;

  &aging;

}


sub deselect_all {

  RP->aging(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $_->{checked} = "" }
  $form->{allbox} = "";

  &aging;

}


sub print_options {

  $form->{copies} ||= 1;
  $form->{PD}{$form->{type}} = "selected";
  
  if ($myconfig{printer}) {
    $form->{format} ||= "postscript";
  } else {
    $form->{format} ||= "pdf";
  }
  $form->{media} ||= $myconfig{printer};

  $form->{sendmode} = "attachment";
  $form->{format} = "pdf" if ($latex && $form->{media} eq 'email');

  if ($form->{media} eq 'email') {
    $media = qq|<select name=sendmode>
	    <option value=attachment>|.$locale->text('Attachment').qq|
	    <option value=inline>|.$locale->text('In-line')
	    .qq|</select>|;

    if ($form->{selectlanguage}) {
      $lang = qq|<select name="language_code_1">|.$form->select_option($form->{selectlanguage}, $form->{language_code_1}, undef, 1).qq|</select>|;
    }
  } else {
    $media = qq|<select name=media>
	    <option value=screen>|.$locale->text('Screen');

    if (%printer && $latex) {
      for (sort keys %printer) { $media .= qq|
            <option value="$_">$_| }
    }
  }
  
  $format = qq|<select name=format>
            <option value="html">html|;
	    
  $type = qq|<select name=type>
	    <option value="statement" $form->{PD}{statement}>|.$locale->text('Statement').qq|</select>|;

  $media .= qq|</select>|;
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  if ($latex) {
    $format .= qq|
            <option value="postscript">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }

  $format .= qq|</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;


  print qq|
<table>
  <tr>
    <td>$type</td>
    <td>$lang</td>
    <td>$format</td>
    <td>$media</td>
|;

  if (%printer && $latex && $form->{media} ne 'email') {
    print qq|
      <td nowrap>|.$locale->text('Copies').qq| 
      <input name=copies size=2 value=$form->{copies}></td>
|;
  }

  $form->{selectlanguage} = $form->escape($form->{selectlanguage},1);
  $form->hide_form(qw(selectlanguage));
  
  print qq|
  </tr>
</table>
|;

}


sub e_mail {

  # get name and email addresses
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"statement_$i"}) {
      $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
      $form->{"statement_1"} = 1;
      $form->{"language_code_1"} = $form->{"language_code_$i"};
      $form->{"curr_1"} = $form->{"curr_$i"};
      RP->get_customer(\%myconfig, \%$form);
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;

  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
          <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  $title = $locale->text('E-mail Statement to')." $form->{$form->{vc}}";

  $form->{media} = "email";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td><input name=email size=30 value="$form->{email}"></td>
	  <th align=right nowrap>|.$locale->text('Cc').qq|</th>
	  <td><input name=cc size=30 value="$form->{cc}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Subject').qq|</th>
	  <td><input name=subject size=30 value="|.$form->quote($form->{subject}).qq|"></td>
	  $bcc
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th align=left nowrap>|.$locale->text('Message').qq|</th>
	</tr>
	<tr>
	  <td><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  &print_options;

  for (qw(email cc bcc subject message type sendmode format action nextsub)) { delete $form->{$_} }

  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=send_email>

<br>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub send_email {

  $form->{OUT} = "$sendmail";

  $form->{subject} = $locale->text('Statement').qq| - $form->{todate}| unless $form->{subject};
  $form->isblank("email", $locale->text('E-mail address missing!'));

  RP->aging(\%myconfig, \%$form);
  
  &print_form;
  
  $form->redirect($locale->text('Statement sent to')." $form->{$form->{vc}}");

}



sub print {

  if ($form->{media} !~ /(screen|email)/) {
    $form->error($locale->text('Select postscript or PDF!')) if ($form->{format} !~ /(postscript|pdf)/);
  }
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"statement_$i"}) {
      $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
      $language_code = $form->{"language_code_$i"};
      $curr = $form->{"curr_$i"};
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;
     
 
  if ($form->{media} !~ /(screen|email)/) {
    $form->{OUT} = "| $printer{$form->{media}}";
    $form->{"$form->{vc}_id"} = "";
    $SIG{INT} = 'IGNORE';
  } else {
    $form->{"statement_1"} = 1;
    $form->{"language_code_1"} = $language_code;
    $form->{"curr_1"} = $curr;
  }

  RP->aging(\%myconfig, \%$form);

  @c = qw(c0 c15 c30 c45 c60 c75 c90);
  $item = $c[0];
  @{$ag} = ();
  
  for (@c) {
    if ($form->{$_}) {
      $item = $_;
    }
    push @{ $ag{$item} }, $_;
  }
 
  for (keys %ag) {
    shift @{ $ag{$_} };
  }
  
  for (keys %ag) {
    for $item (@{ $ag{$_} }) {
      $c{$_} += $c{$item};
    }
  }

  for (@c) {
#    $column_data{$_} = qq|<th align=right>|.$form->format_amount(\%myconfig, $c{$_}{total}, $form->{precision}, "&nbsp").qq|</th>|;
  }
  
  &print_form;

  $form->redirect($locale->text('Statements sent to printer!')) if ($form->{media} !~ /(screen|email)/);

}


sub print_form {
  
  $form->{statementdate} = $locale->date(\%myconfig, $form->{todate}, 1);

  $form->{templates} = "$myconfig{templates}";

  # setup variables for the form
  $form->format_string(qw(company address businessnumber tel fax));
  
  $form->{IN} = "$form->{type}.html";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/html$/tex/;
  }

  @a = qw(name address1 address2 city state zipcode country contact);
  push @a, "$form->{vc}phone", "$form->{vc}fax", "$form->{vc}taxnumber";
  push @a, 'email' if ! $form->{media} eq 'email';

  $i = 0;
  while (@{ $form->{AG} }) {

    $ref = shift @{ $form->{AG} };
    
    if ($vc_id != $ref->{vc_id}) {
      
      $vc_id = $ref->{vc_id};
      $i++;

      if ($form->{"statement_$i"}) {
	
	for (@a) { $form->{$_} = $ref->{$_} }
	$form->format_string(@a);

	$form->{$form->{vc}} = $form->{name};
	$form->{"$form->{vc}_id"} = $ref->{vc_id};
	$form->{language_code} = $form->{"language_code_$i"};
	$form->{currency} = $form->{"curr_$i"};
	
	for (qw(invnumber ordnumber ponumber notes invdate duedate)) { $form->{$_} = () }
	$form->{total} = 0;
	foreach $item (qw(c0 c15 c30 c45 c60 c75 c90)) {
	  $form->{$item} = ();
	  $form->{"${item}total"} = 0;
	}

	&statement_details($ref) if $ref->{curr} eq $form->{currency};

        while ($ref) {

	  if (scalar (@{ $form->{AG} }) > 0) {
	    # one or more left to go
	    if ($vc_id == $form->{AG}->[0]->{vc_id}) {
	      $ref = shift @{ $form->{AG} };
	      &statement_details($ref) if $ref->{curr} eq $form->{currency};
	      # any more?
	      $ref = scalar (@{ $form->{AG} });
	    } else {
	      $ref = 0;
	    }
	  } else {
	    # set initial ref to 0
	    $ref = 0;
	  }

	}
	
	for ("c0", "c15", "c30", "c45", "c60", "c75", "c90", "") { $form->{"${_}total"} = $form->format_amount(\%myconfig, $form->{"${_}total"}, $form->{precision}) }

	$form->parse_template(\%myconfig, $userspath);
	
      }
    }
  }

}


sub statement_details {
  my ($ref) = @_;

  $ref->{invdate} = $ref->{transdate};
  my @a = qw(invnumber ordnumber ponumber notes invdate duedate);
  for (@a) { $form->{"${_}_1"} = $ref->{$_} }
  $form->format_string(qw(invnumber_1 ordnumber_1 ponumber_1 notes_1));
  for (@a) { push @{ $form->{$_} }, $form->{"${_}_1"} }
  
  foreach $item (qw(c0 c15 c30 c45 c60 c75 c90)) {
    eval { $ref->{$item} = $form->round_amount($ref->{$item} / $ref->{exchangerate}, $form->{precision}) };
    $form->{"${item}total"} += $ref->{$item};
    $form->{total} += $ref->{$item};
    push @{ $form->{$item} }, $form->format_amount(\%myconfig, $ref->{$item}, $form->{precision});
  }

}
 

sub generate_tax_report {

  RP->tax_report(\%myconfig, \%$form);

  $descvar = "$form->{accno}_description";
  $description = $form->escape($form->{$descvar});
  
  if ($form->{accno} =~ /^gifi_/) {
    $descvar = "gifi_$form->{accno}_description";
    $description = $form->escape($form->{$descvar});
  }
  
  $department = $form->escape($form->{department});
  
  # construct href
  $href = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&fromdate=$form->{fromdate}&todate=$form->{todate}&db=$form->{db}&method=$form->{method}&summary=$form->{summary}&accno=$form->{accno}&$descvar=$description&department=$department&report=$form->{report}";

  # construct callback
  $description = $form->escape($form->{$descvar},1);
  $department = $form->escape($form->{department},1);

  $form->sort_order();

  $callback = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&fromdate=$form->{fromdate}&todate=$form->{todate}&db=$form->{db}&method=$form->{method}&summary=$form->{summary}&accno=$form->{accno}&$descvar=$description&department=$department&report=$form->{report}";

  $form->{title} = $locale->text('GIFI')." - " if ($form->{accno} =~ /^gifi_/);

  $title = $form->escape($form->{title});
  $href .= "&title=$title";
  $title = $form->escape($form->{title},1);
  $callback .= "&title=$title";
  
  $form->{title} = qq|$form->{title} $form->{"$form->{accno}_description"} |;
  
  if ($form->{db} eq 'ar') {
    $name = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
    $invoice = 'is.pl';
    $arap = 'ar.pl';
    $form->{vc} = "customer";
  }
  if ($form->{db} eq 'ap') {
    $name = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $invoice = 'ir.pl';
    $arap = 'ap.pl';
    $form->{vc} = "vendor";
  }

  @columns = qw(id transdate invnumber description name);
  push @columns, "$form->{vc}number";
  push @columns, qw(netamount tax);
  @columns = $form->sort_columns(@columns);

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }


  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
  
  
  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }
  
  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  }


  $option .= "<br>" if $option;
  $option .= "$form->{period}";
  
 
  $column_header{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</th>|;
  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</th>|;
  $column_header{transdate} = qq|<th nowrap><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</th>|;
  $column_header{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$name</th>|;
  $column_header{"$form->{vc}number"} = qq|<th><a class=listheading href=$href&sort=$form->{vc}number>$vcnumber</th>|;
  
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</th>|;

  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
	</tr>
|;

  # add sort and escape callback
  $callback = $form->escape($callback . "&sort=$form->{sort}");
    
  if (@{ $form->{TR} }) {
    $sameitem = $form->{TR}->[0]->{$form->{sort}};
  }

  foreach $ref (@{ $form->{TR} }) {

    $module = ($ref->{invoice}) ? $invoice : $arap;
    $module = 'ps.pl' if $ref->{till};
    
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&tax_subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }

    $totalnetamount += $ref->{netamount};
    $totaltax += $ref->{tax};

    $subtotalnetamount += $ref->{netamount};
    $subtotaltax += $ref->{tax};
    
    for (qw(netamount tax)) { $ref->{$_} = $form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;"); }
    
    $column_data{id} = qq|<td>$ref->{id}</td>|;
    $column_data{invnumber} = qq|<td><a href=$module?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&callback=$callback>$ref->{invnumber}</a></td>|;

    $column_data{transdate} = qq|<td nowrap>$ref->{transdate}</td>|;
    for (qw(id partnumber description)) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }

    $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
    
    for (qw(netamount tax)) { $column_data{$_} = qq|<td align=right>$ref->{$_}</td>| }

    $i++; $i %= 2;
    print qq|
	<tr class=listrow$i>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
	</tr>
|;
 
  }
 
  if ($form->{l_subtotal} eq 'Y') {
    &tax_subtotal;
  }

  
  for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
  
  print qq|
        </tr>
	<tr class=listtotal>
|;

  $totalnetamount = $form->format_amount(\%myconfig, $totalnetamount, $form->{precision}, "&nbsp;");
  $totaltax = $form->format_amount(\%myconfig, $totaltax, $form->{precision}, "&nbsp;");
  
  $column_data{netamount} = qq|<th class=listtotal align=right>$totalnetamount</th>|;
  $column_data{tax} = qq|<th class=listtotal align=right>$totaltax</th>|;
 
  for (@column_index) { print "$column_data{$_}\n" }
 
    
  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub tax_subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $subtotalnetamount = $form->format_amount(\%myconfig, $subtotalnetamount, $form->{precision}, "&nbsp;");
  $subtotaltax = $form->format_amount(\%myconfig, $subtotaltax, $form->{precision}, "&nbsp;");
  
  $column_data{netamount} = "<th class=listsubtotal align=right>$subtotalnetamount</th>";
  $column_data{tax} = "<th class=listsubtotal align=right>$subtotaltax</th>";

  $subtotalnetamount = 0;
  $subtotaltax = 0;
  
  print qq|
	<tr class=listsubtotal>
|;
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;
  
}



sub list_payments {


  if ($form->{account}) {
    ($form->{paymentaccounts}) = split /--/, $form->{account};
  }
  if ($form->{department}) {
    ($department, $form->{department_id}) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }

  RP->payments(\%myconfig, \%$form);
  
  @columns = (qw(transdate reference description name));
  @columns = $form->sort_columns(@columns);
  push @columns, "$form->{vc}number";
  push @columns, (qw(description paid source memo));

  if ($form->{till}) {
    @columns = (qw(transdate reference name));
    @columns = $form->sort_columns(@columns);
    push @columns, "$form->{vc}number";
    push @columns, (qw(description paid curr source till));
    
    if ($myconfig{role} ne 'user') {
      push @columns, "employee";
    }
  }
  
  # construct href
  $form->{paymentaccounts} =~ s/ /%20/g;
 
  $href = "$form->{script}?action=list_payments";
  @a = (qw(path direction sort oldsort till login fromdate todate fx_transaction db l_subtotal prepayment paymentaccounts vc db));
  for (@a) { $href .= "&$_=$form->{$_}" }
  $href .= "&title=".$form->escape($form->{title});
  
  $form->sort_order();

  $callback = "$form->{script}?action=list_payments";
  for (@a) { $callback .= "&$_=$form->{$_}" }
  $callback .= "&title=".$form->escape($form->{title},1);
  
  if ($form->{account}) {
    $callback .= "&account=".$form->escape($form->{account},1);
    $href .= "&account=".$form->escape($form->{account});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Account')." : $form->{account}";
  }
  if ($form->{department}) {
    $callback .= "&department=".$form->escape($form->{department},1);
    $href .= "&department=".$form->escape($form->{department});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Department')." : $form->{department}";
  }

  %vc = ( customer => { name => 'Customer', 'number' => 'Customer Number' },
          vendor => { name => 'Vendor', 'number' => 'Vendor Number' }
	);

  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1);
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text($vc{$form->{vc}}{name})." : $form->{$form->{vc}}";
  }
  if ($form->{"$form->{vc}number"}) {
    $callback .= qq|&$form->{vc}number=|.$form->escape($form->{"$form->{vc}number"},1);
    $href .= qq|&$form->{vc}number=|.$form->escape($form->{"$form->{vc}number"});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text($vc{$form->{vc}}{number}).qq| : $form->{"$form->{vc}number"}|;
  }
  if ($form->{reference}) {
    $callback .= "&reference=".$form->escape($form->{reference},1);
    $href .= "&reference=".$form->escape($form->{reference});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Reference')." : $form->{reference}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{source}) {
    $callback .= "&source=".$form->escape($form->{source},1);
    $href .= "&source=".$form->escape($form->{source});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Source')." : $form->{source}";
  }
  if ($form->{memo}) {
    $callback .= "&memo=".$form->escape($form->{memo},1);
    $href .= "&memo=".$form->escape($form->{memo});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Memo')." : $form->{memo}";
  }
  if ($form->{fromdate}) {
    $callback .= "&fromdate=$form->{fromdate}";
    $href .= "&fromdate=$form->{fromdate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $callback .= "&todate=$form->{todate}";
    $href .= "&todate=$form->{todate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }
  
  @column_index = ();
  for (@columns) {
    if ($form->{"l_$_"} eq 'Y') {
      push @column_index, $_;
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }
  $colspan = $#column_index + 1;
 
  $form->{callback} = $callback;
  $callback = $form->escape($form->{callback});
 
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text($vc{$form->{vc}}{name})."</a></th>";
  $column_header{"$form->{vc}number"} = "<th><a class=listheading href=$href&sort=$form->{vc}number>".$locale->text($vc{$form->{vc}}{number})."</a></th>";
  $column_header{reference} = "<th><a class=listheading href=$href&sort=reference>".$locale->text('Reference')."</a></th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_header{transdate} = "<th nowrap><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{paid} = "<th class=listheading>".$locale->text('Amount')."</a></th>";
  $column_header{curr} = "<th class=listheading>".$locale->text('Curr')."</a></th>";
  $column_header{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  $column_header{memo} = "<th><a class=listheading href=$href&sort=memo>".$locale->text('Memo')."</a></th>";

  $employee = ($form->{db} eq 'ar') ? $locale->text('Salesperson') : $locale->text('Employee');
  $column_header{employee} = "<th><a class=listheading href=$href&sort=employee>$employee</a></th>";
  $column_header{till} = "<th><a class=listheading href=$href&sort=till>".$locale->text('Till')."</a></th>";
  

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
        </tr>
|;

  $isir = ($form->{db} eq 'ar') ? 'is' : 'ir';
  
  foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{PR} }) {

    next unless @{ $form->{$ref->{id}} };

    print qq|
        <tr>
	  <th colspan=$colspan align=left>$ref->{accno}--$ref->{description}</th>
	</tr>
|;

    if (@{ $form->{$ref->{id}} }) {
      $sameitem = $form->{$ref->{id}}[0]->{$form->{sort}};
    }
    
    foreach $payment (@{ $form->{$ref->{id}} }) {

      if ($form->{l_subtotal}) {
	if ($payment->{$form->{sort}} ne $sameitem) {
	  # print subtotal
	  &payment_subtotal;
	}
      }
      
      next if ($form->{till} && ! $payment->{till});

      $href = ($payment->{vcid}) ? "<a href=ct.pl?action=edit&id=$payment->{vcid}&db=$form->{vc}&login=$form->{login}&path=$form->{path}&callback=$callback>" : "";
      
      $column_data{name} = "<td>$href$payment->{name}</a>&nbsp;</td>";
      $column_data{"$form->{vc}number"} = qq|<td>$payment->{"$form->{vc}number"}&nbsp;</td>|;
      $column_data{description} = "<td>$payment->{description}&nbsp;</td>";
      $column_data{transdate} = "<td nowrap>$payment->{transdate}&nbsp;</td>";
      $column_data{paid} = "<td align=right>".$form->format_amount(\%myconfig, $payment->{paid}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{curr} = "<td>$payment->{curr}</td>";

      if ($payment->{module} eq 'gl') {
	$module = $payment->{module};
      } else {
	if ($payment->{invoice}) {
	  $module = ($payment->{till}) ? 'ps' : $isir;
	} else {
	  $module = $form->{db};
	}
      }
	  
      $href = "<a href=${module}.pl?action=edit&id=$payment->{trans_id}&login=$form->{login}&path=$form->{path}&callback=$callback>";

      $column_data{source} = "<td>$payment->{source}&nbsp;</td>";
      $column_data{reference} = "<td>$href$payment->{reference}&nbsp;</a></td>";
      
      $column_data{memo} = "<td>$payment->{memo}&nbsp;</td>";
      $column_data{employee} = "<td>$payment->{employee}&nbsp;</td>";
      $column_data{till} = "<td>$payment->{till}&nbsp;</td>";

      $subtotalpaid += $payment->{paid};
      $accounttotalpaid += $payment->{paid};
      $totalpaid += $payment->{paid};
       
      $i++; $i %= 2;
      print qq|
	<tr class=listrow$i>
|;

      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
        </tr>
|;

      $sameitem = $payment->{$form->{sort}};
      
    }

    &payment_subtotal if $form->{l_subtotal};
    
    # print account totals
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $accounttotalpaid, $form->{precision}, "&nbsp;")."</th>";
     
    print qq|
	<tr class=listtotal>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    $accounttotalpaid = 0;
     
  }


  # print total
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalpaid, $form->{precision}, "&nbsp;")."</th>";
     
  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

#################
#  &print_report_options;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
 
</body>
</html>
|;

}


sub payment_subtotal {

  if ($subtotalpaid != 0) {
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalpaid, $form->{precision}, "&nbsp;")."</th>";

    print qq|
  <tr class=listsubtotal>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
  </tr>
|;
  }

  $subtotalpaid = 0;

}


sub print_report_options {

  $form->{format} ||= "pdf";
  $form->{media} ||= "screen";
  
  $media = qq|<select name=media>
	    <option value=screen $form->{MD}{screen}>|.$locale->text('Screen').qq|
	    <option value=file $form->{MD}{file}>|.$locale->text('File');

  $format = qq|<select name=format>
            <option value=csv $form->{DF}{csv}>CSV|;
	    
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
  $media .= qq|</select>|;

  if ($latex) {
    $format .= qq|
	    <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF').qq|
            <option value=postscript $form->{DF}{postscript}>|.$locale->text('Postscript');
  }
  $format .= qq|</select>|;
  
  print qq|
<form method=post action=$form->{script}>

<table>
  <tr>
    <td>$format</td>
    <td>$media</td>
|;

  print qq|
  </tr>
</table>

<p>
<input class=submit type=submit name=action value="|.$locale->text('Print Report').qq|">|;

  $form->{action} = "print_report";
  $form->{nextsub} = "";
  
  $form->hide_form;

  print qq|
</form>
|;

}


sub print_report {

  $form->debug;

}


