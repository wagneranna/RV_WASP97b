# ECHELLE SPECTROSCOPY REDUCTION

"""
CL Script for reduction of Echelle spectroscopy data
for use with IRAF (packages: noao - imred - echelle)

Created by Anna Wagner for Workshop on Observational Techniques 2024 in Ondrejov
"""

# 0 LISTS

# create list of bias, flat, comp & object frames
ls *Bias.fits > bias.lis
ls *Flat.fits > flat.lis
ls *Comp.fits > comp.lis
ls *WASP-97.fits > object.lis


# 1 BIAS

# combine all bias frames to create master bias
imcombine ("@bias.lis",
"bias.fits", headers="", bpmasks="", rejmasks="", nrejmasks="", expmasks="",
sigmas="", imcmb="$I", logfile="STDOUT", combine="average", reject="sigclip",
project=no, outtype="real", outlimits="", offsets="none", masktype="none",
maskvalue="0", blank=0., scale="none", zero="none", weight="none", statsec="",
expname=" ", lthreshold=INDEF, hthreshold=INDEF, nlow=1, nhigh=1, nkeep=1,
mclip=yes, lsigma=3., hsigma=3., rdnoise="0.", gain="1.", snoise="0.",
sigscale=0.1, pclip=-0.5, grow=0.)

# determine mean bias level
# the scanf function takes the value of the first 6 digits of the bias

imstat ("bias.fits",
fields="mean", lower=INDEF, upper=INDEF, nclip=0, lsigma=3., usigma=3.,
binwidth=0.1, format=no, cache=no) | scanf("%6f", x)


# 2 FLAT

# combine all flat frames
imcombine ("@flat.lis",
"flat.fits", headers="", bpmasks="", rejmasks="", nrejmasks="", expmasks="",
sigmas="", imcmb="$I", logfile="STDOUT", combine="average", reject="sigclip",
project=no, outtype="real", outlimits="", offsets="none", masktype="none",
maskvalue="0", blank=0., scale="median", zero="none", weight="median",
statsec="", expname=" ", lthreshold=INDEF, hthreshold=INDEF, nlow=1, nhigh=1,
nkeep=1, mclip=yes, lsigma=3., hsigma=3., rdnoise="0.", gain="1.",
snoise="0.", sigscale=0.1, pclip=-0.5, grow=0.)

# subtract bias
imarith ("flat.fits",
"-", x, "flat_b.fits", title="", divzero=0., hparams="", pixtype="",
calctype="", verbose=no, noact=no)

# find spectral orders
apall ("find_orders.fits",
48, output="dummy.fits", apertures="", format="echelle",
references=" ", profiles="", interactive=no, find=yes,
recenter=yes, resize=no, edit=yes, trace=yes, fittrace=yes, extract=yes,
extras=no, review=yes, line=INDEF, nsum=10, lower=-5., upper=5.,
apidtable=" ", b_function="chebyshev", b_order=1, b_sample="-10:-6,6:10",
b_naverage=-3, b_niterate=0, b_low_reject=3., b_high_rejec=3., b_grow=0.,
width=5., radius=10., threshold=0., minsep=5., maxsep=100000.,
order="increasing", aprecenter="", npeaks=INDEF, shift=yes, llimit=INDEF,
ulimit=INDEF, ylevel=0.1, peak=yes, bkg=yes, r_grow=0., avglimits=no,
t_nsum=5, t_step=5, t_nlost=5, t_function="legendre", t_order=5, t_sample="*",
t_naverage=1, t_niterate=0, t_low_reject=3., t_high_rejec=3., t_grow=0.,
background="none", skybox=1, weights="none", pfit="fit1d", clean=no,
saturation=INDEF, readnoise="0.", gain="1.", lsigma=4., usigma=4., nsubaps=1)

# set parameters for aptrace
aptrace (" ",
apertures="", references="", interactive=no, find=yes, recenter=no, resize=no,
edit=no, trace=yes, fittrace=yes, line=INDEF, nsum=10, step=10, nlost=3,
function="legendre", order=5, sample="*", naverage=1, niterate=0,
low_reject=3., high_reject=3., grow=0.)

# create master flat
apflatten ("flat_b.fits",
"masterflat.fits", apertures="", references="find_orders", interactive=no,
find=yes, recenter=no, resize=no, edit=yes, trace=yes, fittrace=yes,
flatten=yes, fitspec=no, line=INDEF, nsum=10, threshold=10., pfit="fit1d",
clean=yes, saturation=INDEF, readnoise="0.", gain="1.", lsigma=4., usigma=4.,
function="legendre", order=10, sample="*", naverage=1, niterate=0,
low_reject=3., high_reject=3., grow=0.)

# check distribution
imhist ("masterflat.fit",
z1=INDEF, z2=INDEF, binwidth=INDEF, nbins=512, autoscale=yes, top_closed=no,
hist_type="normal", listout=no, plot_type="line", logy=yes, device="stdgraph")

# remove strange values
real lower

imreplace ("masterflat.fit",
1., imaginary=0., lower=lower, upper=INDEF, radius=0.)

real upper

imreplace ("masterflat.fit",
1., imaginary=0., lower=INDEF, upper=upper, radius=0.)

#check distribution again
imhist ("masterflat.fit",
z1=INDEF, z2=INDEF, binwidth=INDEF, nbins=512, autoscale=yes, top_closed=no,
hist_type="normal", listout=no, plot_type="line", logy=yes, device="stdgraph")


# 3 SCIENCE FRAMES

# subtract bias & save in new object list (a)
imarith ("@object.lis",
"-", x, "@object.lis//a", title="", divzero=0., hparams="",
pixtype="", calctype="", verbose=no, noact=no)

ls *a.fits > objecta.lis

# divide by flat & save in new object list (b)
imarith ("@objecta.lis",
"/", "masterflat.fit", "@object.lis//b", title="", divzero=0., hparams="",
pixtype="", calctype="", verbose=no, noact=no)

ls *b.fits > objectb.lis

# subtract scattered light & save in new object list (c)
apscatter ("@objectb.lis",
"@object.lis//c", apertures="", scatter="", references="find_orders",
interactive=no, find=no, recenter=no, resize=no, edit=no, trace=no,
fittrace=no, subtract=yes, smooth=yes, fitscatter=yes, fitsmooth=yes,
line=INDEF, nsum=10, buffer=1., apscat1="", apscat2="")

ls *c.fit > objectc.lis

# extract the spectra & save in new object list (d)
apall ("@objectc.lis",
48, output="@object.lis//d", apertures="", format="echelle",
references="find_orders", profiles="", interactive=no, find=yes, recenter=yes,
resize=no, edit=yes, trace=no, fittrace=no, extract=yes, extras=no,
review=yes, line=INDEF, nsum=10, lower=-5., upper=5., apidtable=" ",
b_function="chebyshev", b_order=1, b_sample="-10:-6,6:10", b_naverage=-3,
b_niterate=0, b_low_reject=3., b_high_rejec=3., b_grow=0., width=5.,
radius=10., threshold=0., minsep=5., maxsep=100000., order="increasing",
aprecenter="", npeaks=INDEF, shift=yes, llimit=INDEF, ulimit=INDEF,
ylevel=0.1, peak=yes, bkg=yes, r_grow=0., avglimits=no, t_nsum=5, t_step=5,
t_nlost=5, t_function="legendre", t_order=5, t_sample="*", t_naverage=1,
t_niterate=0, t_low_reject=3., t_high_rejec=3., t_grow=0., background="none",
skybox=1, weights="none", pfit="fit1d", clean=no, saturation=INDEF,
readnoise="0.", gain="1.", lsigma=4., usigma=4., nsubaps=1)

ls *d.fit > objectd.lis


# 4 COMP FRAMES

# subtract bias & save in new comp list (a)
imarith ("@comp.lis",
"-", x, "@comp.lis//a", title="", divzero=0., hparams="",
pixtype="", calctype="", verbose=no, noact=no)

ls *Compa.fits > compa.lis

# divide by flat & save in new comp list (b)
imarith ("@compa.lis",
"/", "masterflat.fit", "@comp.lis//b", title="", divzero=0., hparams="",
pixtype="", calctype="", verbose=no, noact=no)

ls *Compb.fits > compb.lis

# subtract scattered light & save in new comp list (c)
apscatter ("@compb.lis",
"@comp.lis//c", apertures="", scatter="", references="find_orders",
interactive=no, find=no, recenter=no, resize=no, edit=no, trace=no,
fittrace=no, subtract=yes, smooth=yes, fitscatter=yes, fitsmooth=yes,
line=INDEF, nsum=10, buffer=1., apscat1="", apscat2="")

ls *Compc.fit > compc.lis

# extract the spectra & save in new comp list (d)
apall ("@compc.lis",
48, output="@comp.lis//d", apertures="", format="echelle",
references="find_orders", profiles="", interactive=no, find=yes, recenter=yes,
resize=no, edit=yes, trace=no, fittrace=no, extract=yes, extras=no,
review=yes, line=INDEF, nsum=10, lower=-5., upper=5., apidtable=" ",
b_function="chebyshev", b_order=1, b_sample="-10:-6,6:10", b_naverage=-3,
b_niterate=0, b_low_reject=3., b_high_rejec=3., b_grow=0., width=5.,
radius=10., threshold=0., minsep=5., maxsep=100000., order="increasing",
aprecenter="", npeaks=INDEF, shift=yes, llimit=INDEF, ulimit=INDEF,
ylevel=0.1, peak=yes, bkg=yes, r_grow=0., avglimits=no, t_nsum=5, t_step=5,
t_nlost=5, t_function="legendre", t_order=5, t_sample="*", t_naverage=1,
t_niterate=0, t_low_reject=3., t_high_rejec=3., t_grow=0., background="none",
skybox=1, weights="none", pfit="fit1d", clean=no, saturation=INDEF,
readnoise="0.", gain="1.", lsigma=4., usigma=4., nsubaps=1)

ls *Compd.fit > compd.lis


# 5 WAVELENGTH CALIBRATION

# identify lines
string calibration_file

ecreidentify ("@compd.lis",
calibration_file, shift=0., cradius=5., threshold=10., refit=yes, database="database",
logfiles="STDOUT,logfile")

bool log

# assign comp frames to science frames
refspectra ("@objectd.lis",
"yes", references="@compd.lis", apertures="", refaps="", ignoreaps=yes,
select="average", sort=" ", group=" ", time=no, timewrap=17., override=yes,
confirm=yes, assign=yes, logfiles="STDOUT,logfile", verbose=yes)

# calibrate wavelength scale
dispcor ("@objectd.lis",
"@object.lis//e", linearize=yes, database="database", table="", w1=INDEF,
w2=INDEF, dw=INDEF, nw=INDEF, log=no, flux=yes, blank=0., samedisp=yes,
global=no, ignoreaps=yes, confirm=no, listonly=no, verbose=yes, logfile="")

ls *e.fits > objecte.lis


# 6 REDUCED SPECTRA

# check reduced spectra
# splot @objecte.lis
