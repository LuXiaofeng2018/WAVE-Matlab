function [theta_table, temp_table] =convert_climate_to_daily(crop_climate,irri,ET0_cm_per_day)

%Summarize data files to daily files
%JD H Rad T RH
uniquetimes = unique(crop_climate(:,1));
for i=min(uniquetimes):max(uniquetimes)
    index = find(crop_climate(:,1) ==i);
    dailyrain(i-min(uniquetimes)+1,1) = sum(crop_climate(index,6));
    temp_max(i-min(uniquetimes)+1,1) = max(crop_climate(index,4));
    temp_min(i-min(uniquetimes)+1,1) = min(crop_climate(index,4));
end

%Export to usable tables
theta_table = (min(uniquetimes):max(uniquetimes))';
theta_table(:,2) = ET0_cm_per_day';
theta_table(:,3) = dailyrain;
theta_table(:,4) = 0;
theta_table(:,4) = 0;

for i=1:length(irri)
    index = (find(irri(i) == theta_table(:,1)));
    if isempty(index)==0
        theta_table(index,4) = irri(i,2);
    end    
end



%dlmwrite('theta_table.txt', theta_table,'precision',12)

temp_table =(min(uniquetimes):max(uniquetimes))';
temp_table(:,3) = temp_max;
temp_table(:,2) = temp_min;
%dlmwrite('temperature_table.txt', temp_table,'precision',12)
