To run this module, you must install the following modules:
PDF::Reuse

Both modules are available from CPAN.  To install, as root:
perl -MCPAN -e 'install [module_name]' where module_name is
defined above

After installing PDF::Reuse, Please made the changes in /usr/lib/perl5/site_perl/5.8.5/PDF/Reuse.pm as given below

245c245,247
<           ||     ($key eq 'centerwindow'))
---
>           ||     ($key eq 'centerwindow')
>           ||     ($key eq 'xwidth')
>           ||     ($key eq 'yheight'))
256a259,260
>       $prefs{xwidth}       = $_[6]  if defined $_[6];
>       $prefs{yheigth}      = $_[7]  if defined $_[7];
359,361c363,366
<    $genUpperX = 595,
<    $genUpperY = 842;
<
---
>    $genUpperX = 612,
>    $genUpperY = 792;
>    $genUpperX = (exists $prefs{xwidth})  ? $prefs{xwidth}  : $genUpperX;
>    $genUpperY = (exists $prefs{yheight}) ? $prefs{yheight} : $genUpperY;
