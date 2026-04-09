-- Données approximatives d'inscription à Harvard (source: NCES IPEDS / collegetuitioncompare.com)
select year, total_enrollment, undergraduate_enrollment
from (values
    (1998, 18836, 6664),
    (1999, 19264, 6651),
    (2000, 19537, 6649),
    (2001, 19647, 6650),
    (2002, 19731, 6649),
    (2003, 19714, 6652),
    (2004, 19955, 6655),
    (2005, 19960, 6657),
    (2006, 21017, 6658),
    (2007, 21029, 6660),
    (2008, 21095, 6678),
    (2009, 21024, 6694),
    (2010, 21225, 6699),
    (2011, 21152, 6676),
    (2012, 21006, 6658),
    (2013, 21000, 6676),
    (2014, 21526, 6694),
    (2015, 22029, 6700),
    (2016, 22370, 6710),
    (2017, 23320, 6740),
    (2018, 23731, 6766),
    (2019, 23731, 6788)
) as t(year, total_enrollment, undergraduate_enrollment)
order by year
