function [ph,wat_flxs,dt,iter,runoff,no_conv,WC,bctop_changed,bcbot_changed,pond,...
  phsurf,flxar,boco_top_type,boco_bot_type,rtex,EPRA,esa] =...
   solve_flow(ph,t,dt,compartiments_number,iter,boco_top_type,boco_top,boco_bot_type,...
   boco_bot,pond,flxa1,dt_start,dx,dx_inter,stock_max,seep,soil_parameters,ponded,pond_from,...
   hs,phsa,maxiter,dt_min,phsurf,phbot,flxsbot,flxar,bctop_changed,bcbot_changed,err_tol,...
   simplant,units,plant_date,harvest_date,ncbot,wat_flxs);

%SOLVE_FLOW Solve the 1-D water flow equation using finite differences
%
% IN:
%   ph = the initial pressure head (cm)
%   t = time (min)
%   dt = the time increment (min)
%   Characteristics of the soil: compartiments_number,dx,dx_inter,soil_parameters,stock_max
%   General characteristics:maxiter,dt_min,err_tol,dt_start,hs,phsa,err_tol,simplant
%   Current boundary specifications:boco_top_type,boco_top,boco_bot_type,boco_bot,seep,ponded,
%       pond_from,iter,bctop_changed,bcbot_changed
%   Current soil values: phsurf,phbot,flxsbot,flxar,pond,flxa1
% OUT:
%   ph = the updated pressure head (cm)
%   wat_flxs = flow at each node (cm/min)
%   dt = the update time step (min)
%   iter = number of solve_flow iterations
% CALL:
%   state_var,conduct_in,thomas_block2,calc_fluxes,check_balance,calc_dt
% CALLED BY:
%   wavemat101.m
%
%----------------------------------
% M. Vanclooster, 13/1/2000
% modified by M. Javaux, 14/05/00, updating 1:17-11-00
% modified by M.Sall, 25/11/09 


%initialization
ncs=compartiments_number;
%put the "changement variables" equal to zero
bcbot_changed=0;bctop_changed=0;DX(1:ncs)=dx;
iter_dx=0;itertop=0;
top_OK=0;bot_OK=0;no_conv=0;

%initial calculations
[WC,kh,CH,rtex,EPRA,esa]=state_var(ph,soil_parameters,dt,0,t,simplant,dx,units,plant_date,harvest_date);
phB = ph;WCB = WC; khB=kh; CHB=CH; rtexB=rtex;EPRAB=EPRA; esaB=esa;
kh_in=conduct_in(ph,boco_top_type,phsurf,phsa,flxar,soil_parameters);
kh_inB=kh_in; flxa1B=flxa1;

%calculates current boundary conditions
[seep,boco_top_type,boco_bot_type,dt,bctop_changed,...
      bcbot_changed,flxar,phbot,phsurf,flxsbot]=calc_boco(dx,kh_in,ph,dt,rtex,t,...
   	compartiments_number,pond,boco_bot,boco_top_type,boco_bot_type,...
      flxa1,stock_max,bctop_changed,bcbot_changed,soil_parameters,flxar,...
      phsa,phsurf,phbot,flxsbot,ponded,pond_from);

  seepB=seep; boco_top_typeB=boco_top_type; boco_topB=boco_top;
  boco_bot_typeB=boco_bot_type; boco_botB=boco_bot;  bctop_changedB=bctop_changed; 
      bcbot_changedB=bcbot_changed; flxarB= flxar; phbotB=phbot; phsurfB=phsurf; flxsbotB =flxsbot;
  top_OKB=top_OK;bot_OKB=bot_OK;
  
  
%Resolves Thomas block by Newton-Raphson
while (dt >=dt_min) &(top_OK==0)&(itertop<=3)
	if itertop==2
      [phsurf,boco_top_type]=fix_uboco(phsa,pond,flxar);
      disp('fix')
	end   
   itertop=itertop+1;
   ph=phB;
   [WC,kh,CH,rtex,EPRA,esa]=state_var(ph,soil_parameters,dt,0,t,simplant,dx,units,plant_date,harvest_date);
   kh_in=conduct_in(ph,boco_top_type,phsurf,phsa,flxar,soil_parameters);

   % in case of free drainage,re(calculate) flxsbot
   if boco_bot_type==4					
   	flxsbot=-kh_in(compartiments_number+1);  
   end
   balance_error = 1;
   while balance_error  ==1
   	iter = 0; 
      while balance_error==1 & (iter < maxiter)
        	iter = iter + 1;
         % call thomasblock to inverse tridiag. matrix
         ph = thomas_block2(ph,WC,WCB,kh,kh_in,CH,rtex,dt,DX,dx_inter,...
              phsurf,phbot,flxsbot,flxar,boco_top_type,boco_bot_type,...
              ncbot);

           %recalculate state variables: kh,WC,...
         [WC,kh,CH,rtex,EPRA,esa]=state_var(ph,soil_parameters,dt,0,t,simplant,dx,units,plant_date,harvest_date);
         %Calculation of the hydraulic conductivity in between the nodes
         kh_in=conduct_in(ph,boco_top_type,phsurf,phsa,flxar,soil_parameters);
         %Calculation of the soil water fluxes across the soil nodes
      	[wat_flxs,iter] = calc_fluxes (ph,kh_in,dt,phsurf,pond,flxsbot,phbot,flxar,...
            boco_top_type,boco_bot_type,maxiter,dx_inter,compartiments_number,iter);
        
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
         if ncbot~=ncs;    
            for k=ncbot:ncs;
            WC(k)=moist_ret(0,soil_parameters(k,:),dt,0);
  %          wat_flxs(k+1)=wat_flxs(k)+((WC(k)-WCB(k))/dt+rtex(k))*dx;
             wat_flxs(k+1)= ((WC(k)-WCB(k))./dt+rtex(k))*dx +wat_flxs(k);
            ph(k)=ph(k-1)+(wat_flxs(k)/kh_in(k)+1.)*dx_inter(k);
            end
         end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            
            
         %check of the balance
         balance_error = check_balance(wat_flxs,WC,WCB,rtex,dt,dx,compartiments_number,err_tol);
         % in case of free drainage,re(calculate) flxsbot
         if boco_bot_type==4					
   			flxsbot=-kh_in(compartiments_number+1);    
       
		end
      end
      if iter == maxiter & balance_error
      	dt=dt/2;  %%%dt=dt/2;
      	if dt < dt_min
	         no_conv=1;
         	break;
      	else 
        	 	disp('time step diminution');
   %%%Restore initial situation
   WC = WCB; kh=khB; CH=CHB; rtex=rtexB; EPRA=EPRAB; esa=esaB;
   kh_in=kh_inB;
   seep=seepB; boco_top_type=boco_top_typeB; boco_bot_type=boco_bot_typeB; bctop_changed=bctop_changedB; 
      bcbot_changed=bcbot_changedB; flxar= flxarB; phbot=phbotB; phsurf=phsurfB; flxsbot =flxsbotB;
     boco_top=boco_topB; boco_bot=boco_botB; top_OK=top_OKB;bot_OK=bot_OKB;flxa1=flxa1B;
     
      		ph = phB ;  
            [WC,kh,CH,rtex,EPRA,esa]=state_var(ph,soil_parameters,dt,0,t,simplant,dx,units,plant_date,harvest_date);
            kh_in=conduct_in(ph,boco_top_type,phsurf,phsa,flxar,soil_parameters);
[seep,boco_top_type,boco_bot_type,dt,bctop_changed,...
      bcbot_changed,flxar,phbot,phsurf,flxsbot]=calc_boco(dx,kh_in,ph,dt,rtex,t,...
   	compartiments_number,pond,boco_bot,boco_top_type,boco_bot_type,...
      flxa1,stock_max,bctop_changed,bcbot_changed,soil_parameters,flxar,...
      phsa,phsurf,phbot,flxsbot,ponded,pond_from);

         end       
      end 
   end
	[top_OK, bot_OK,bctop_changed,bcbot_changed,phsurf,phbot,flxsbot,boco_top_type,...
    boco_bot_type]=check_bc(wat_flxs,ph,kh_in,compartiments_number,dx_inter,pond,phsa,...
   	flxar,boco_top_type,boco_bot_type,seep,phsurf,phbot,flxsbot,bctop_changed,...
   	bcbot_changed); 
end


%ponding
pond=min([hs  max([0 (wat_flxs(1)-flxar)*dt])]);

%in case of hysteresis
if soil_parameters(1,7)~=1
   WC = moist_ret(ph,soil_parameters,dt,1);
end

%Runoff generation
if pond <hs & pond >0
   disp(sprintf('Ponding:%4.5f cm',pond));
end

if (pond==hs & pond~=0)|(hs==0 & (wat_flxs(1)-flxar)*dt>0)
   runoff=((wat_flxs(1)-flxar)*dt-hs)/dt;
   disp(['Runoff generation: ',num2str(runoff),' cm/minutes (=',num2str(abs(runoff/flxar)),'% of the prescribed flux)']);
else
   runoff=0;
end

