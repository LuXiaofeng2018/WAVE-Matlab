function stock = calc_stock(ph,dx,soil_parameters,dt,update_historic);

% CALC_STOCK    Calculates the stock of the whole sample
%
%IN:
%	ph = pressure head (cm)
%OUT:
%	stock = water storage in the profile (cm)
%CALL:
%   moist_ret.m
%CALLED BY
%   wavemat.m
%-------------------
% M. Javaux 15/05/2000

WC = moist_ret(ph,soil_parameters,dt,update_historic);
stock=sum(WC.*dx);

