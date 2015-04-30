function [diags, plotx] = print_diag(runArray, name)
    if isempty(runArray.filter)
        runArray.filter = 1:runArray.len;
    end

    plots = 1;
    annostr = ['runArray.print_diag(' name ')'];
    diags = nan(size(runArray.filter));

    if plots
        hfig = figure;
        % add function call as annotation
        insertAnnotation(['runArray.print_diag(' name ')']);
        hold all;
        hax = gca; % default axes
        name_points = 1; % name points by default
        line_45 = 0; %no 45° line by default
        errorbarflag = 0; % use errorbar() instead of plot()
        kozak = 0; % fancy Kozak scatterplot
        labx = ' '; laby = ' ';
        clr = 'k';
        plotx = []; error = [];
        titlestr = name;
    end

    for ff=1:length(runArray.filter)
        ii = runArray.filter(ff);
        run = runArray.array(ii);
        runName = runArray.getname(ii);

        ptName = runName;

        % some commonly used variables
        tind = run.tscaleind;
        [~,uind,~] = unique(run.time, 'stable');
        ndtime = run.eddy.t * 86400 / run.eddy.turnover;
        Lx = run.eddy.vor.lmaj;
        Ly = run.eddy.vor.lmin;
        Lz = run.eddy.Lgauss;
        Ls = run.eddy.Ls;
        Ro = run.eddy.Ro;
        V = run.eddy.V;
        if isfield(run.eddy, 'Vb'), Vb = run.eddy.Vb; end

        hedge = NaN; %run.eddy.hedge;
        hcen = run.eddy.hcen;
        fcen = run.eddy.fcen;
        my = run.eddy.my;
        mx = run.eddy.mx;

        A = run.eddy.amp(1);

        Lr = run.rrdeep;
        beta = run.params.phys.beta;
        use run.params.phys
        f0 = abs(f0);

        alpha = run.bathy.sl_slope;
        hsb = run.bathy.hsb;
        hsl = run.bathy.hsl;
        xsb = run.bathy.xsb;
        xsl = run.bathy.xsl;
        Sa = run.bathy.S_sl;
        beta_t = f0 * alpha./Lz(1);
        N = sqrt(run.params.phys.N2);
        diagstr = [];

        %%%%% dummy
        if strcmpi(name, 'dummy')

            % for local plots
            %figure; hold all
            %cb = runArray.sorted_colors;
            sortedflag = 0;

            diags(ff) = [];
            % x-axis variable for plots
            plotx(ff) = [];
            % label points with run-name?
            name_points = 0;
            % x,y axes labels
            labx = [];
            laby = [];
        end

        %%%%% cross-isobath translation velocity
        if strcmpi(name, 'mvy')

            local_plot = 0;

            if local_plot
                % for local plots
                if ff == 1
                    hfig2 = figure; hold all
                    cb = runArray.sorted_colors;
                    sortedflag = 1;
                end
            end

            Ro = Ro(1);

            % convert to m/s
            mvy = smooth(run.eddy.mvy, 28) * 1000/86400;
            [diags(ff), ind] = min(mvy);
            diags(ff) = abs(diags(ff));

            if local_plot
                ndtime = run.eddy.t * 86400 ./ ...
                         run.eddy.turnover;
                figure(hfig2);
                hgplt = plot(ndtime, mvy);
                addlegend(hgplt, runName);
                plot(ndtime(ind), mvy(ind), 'k*');
            end

            % make normal summary plot?
            plots = 1;
            % x-axis variable for plots
            plotx(ff) = 5*(1+Sa)^(-1).*(beta.*Lr^2).^2 .* f0*Lr./9.81./A;
            % label points with run-name?
            name_points = 1;
            % x,y axes labels
            labx = 'Parameterization';
            laby = 'max |cross-isobath velocity|';
        end

        %%%%% cross-shelf translation time scale
        if strcmpi(name, 'timescale')
            run.fit_traj;

            vel = smooth(run.eddy.cvy, 20);

            % stalling isobath
            h0 = Lz(1) * erfinv(1 - beta/beta_t);

            t0 = run.eddy.tscaleind;

            vel = smooth(run.eddy.mvy, 20);

            %figure;
            %plot(vel);hold all
            %plot(smooth(vel, 20));
            diags(ff) = run.traj.tscl;
            plotx(ff) = beta/f0 .* Lz(t0).^2 ./ alpha^2 .* ...
                exp( (hcen(1)/Lz(1)) ^2) ./ max(-1*vel(1:100));
            %name_points = 0;
            %diags(ff) = -1 * min(vel)./run.eddy.V(1);
            %plotx(ff) = run.params.nondim.eddy.Rh;
        end

        %%%%% slope parameter
        if strcmpi(name, 'slope param')
            plots = 0;
            diags(ff) = beta/beta_t;
            plotx(ff) = NaN;
        end

        %%%%%
        if strcmpi(name, 'aspect')
            run.fit_traj(1.5);

            tind = run.traj.tind;

            H = hcen(tind);

            diags(ff) = H./Lz(run.eddy.tscaleind);
            plotx(ff) = beta/beta_t;

            laby = 'H/Lz';
            labx = 'index';
        end

        %%%%% resistance
        if strcmpi(name, 'resistance')
            [xx,yy,tind] = run.locate_resistance;

            loc = 'cen';
            loc = 'edge';

            % save for later
            run.eddy.res.xx = xx;
            run.eddy.res.yy = yy;
            run.eddy.res.tind = tind;
            run.eddy.res.comment = ['(xx,yy) = center ' ...
                                'location | tind = time index'];

            plotx(ff) = 1./(1+Ro(1));
            %diags(ff) = yy./run.rrdeep;
            if strcmpi(loc, 'cen')
                hdiag = run.eddy.hcen(tind);
                laby = 'H_{cen}./H_{eddy}';
            else
                if run.bathy.axis == 'y'
                    xind = find_approx(run.rgrid.y_rho(:,1), ...
                                       run.eddy.vor.se(tind), ...
                                       1);
                    hdiag = run.bathy.h(1,xind)
                else
                    xind = find_approx(run.rgrid.x_rho(1,:), ...
                                       run.eddy.vor.we(tind), ...
                                       1);
                    hdiag = run.bathy.h(xind,1)
                end
                laby = 'H_{edge}./H_{eddy}';
            end

            diags(ff) = hdiag ./ Lz(1);

            % name points with run names on summary plot
            name_points = 1;
            labx = 'Ro/S_\alpha';
        end

        %%%%% energy loss - as vertical scale
        if strcmpi(name, 'dhdt')
            use_traj = 1;
            if use_traj
                run.fit_traj(1.5);
                tind = run.traj.tind;
            else
                [~,~,tind] = run.locate_resistance;
            end

            diags(ff) = (Lz(tind) - Lz(1))./Lz(1);
            plotx(ff) = V(1)./beta./Ls(1).^2;

            laby = '\Delta L_z / L_z^0';
            labx = 'U/\beta L_s^2';
            %plotx(ff) = beta*Ls(1)/f0;% - much worse
        end

        % can run cross shelfbreak?
        if strcmpi(name, 'cross sb')
            tind = find_approx((run.eddy.vor.se - xsb), 0);

            % figure;
            % plot(Lz); linex(tind); liney(hsb);
            % title(run.name);
            % continue;

            diags(ff) = Lz(tind)/hsb;
            plotx(ff) = V(1)./beta./Ls(1).^2;

            laby = '\Delta L_z / L_z^0';
            labx = 'U/\beta L_s^2';
        end


        %%%%% energy loss
        if strcmpi(name, 'dEdt')
            [~,~,tind] = run.locate_resistance;
            PE = abs(run.eddy.PE(1:tind,1));
            KE = run.eddy.KE(1:tind,1);

            tvec = ndtime(1:tind)';
            %dPEdt = nanmean(fillnan(smooth(diff(PE./PE(1))./ ...
            %                    diff(tvec), 30), Inf));
            %dKEdt = nanmean(fillnan(smooth(diff(KE./KE(1))./ ...
            %                    diff(tvec), 30), Inf));


            [~,pind] = min(PE(5:end));
            [~,kind] = min(KE(5:end));

            use_polyfit = 0;
            if use_polyfit
                PEfit = polyfit(tvec(1:pind), PE(1:pind)./PE(1), 1);
                KEfit = polyfit(tvec(1:kind), KE(1:kind)./KE(1), 1);
            else
                [PEfit,bint,r,rint,stats] = regress(PE(1:pind)./PE(1), ...
                                                    [tvec(1:pind) ...
                                    ones([pind 1])]);
                error_PE = bint(1,2) - PEfit(1);

                [KEfit,bint,r,rint,stats] = regress(KE(1:kind)./KE(1), ...
                                                    [tvec(1:kind) ...
                                    ones([kind 1])]);
                error_KE = bint(1,2) - KEfit(1);
            end

            dPEdt = (PE(pind))./PE(1) - 1; %PEfit(1);
            dKEdt = (KE(kind))./KE(1) - 1; %KEfit(1);

            en = 'PE';

            %laby = ['|d' en '/dt|'];
            laby = ['\Delta' en '/' en '(0)'];

            %figure; hold all;
            %plot(tvec, PE./PE(1)); plot(tvec, tvec*PEfit(1) + ...
            %                            PEfit(2));
            %title(run.name);
            %plot(tvec, KE./KE(1)); plot(tvec, tvec*KEfit(1) + KEfit(2));

            eval(['diags(ff) = abs(d' en 'dt);']);
            plotx(ff) = beta * Lx(1) ./ f0; %...
            %(beta * Lz(1) - alpha * f0 * (1-erf(hedge(1)./Lz(1))));
            eval(['error(ff) = abs(error_' en ');']);

            errorbarflag = 1;
            name_points = 1;
            labx = '\beta L / f_0';
            %labx = ['$$\beta L_z - ' ...
            %        'f_0 \alpha_{bot} (1 - \mathrm{erf} (h_{edge}/L_z) )  $$'];
            titlestr = '';
        end

        if strcmpi(name, 'energy loss old')

            % algorithm:
            %  1. Detect the minimum in vertical scale.
            %  2. approximate dh/dt as Δh/Δt
            %  3. compare with cg estimate
            %
            % Non-dimensionalizations:
            %  1. time → eddy turnover time
            %  2. height → initial vertical scale of eddy

            time =  run.eddy.t * 86400;
            ndtime = time ./ (run.eddy.vor.lmaj(1)./run.eddy.V(1));

            try
                if any(size(run.eddy.KE) == 1)
                    TE = run.eddy.KE + run.eddy.PE;
                else
                    TE = run.eddy.KE(:,1) + run.eddy.PE(:,1);
                end
            catch ME
                disp(run.name);
                continue;
            end

            vec = smooth(TE, 30);
            [xmax, imax, xmin, imin] = extrema(vec);

            % find the first minima in the height time series
            % presumably, this gives me a good slope
            imins = sort(imin, 'ascend');
            index = imins(find(imins > 30, 1, 'first'))

            fig = 0;
            if fig
                field = run.eddy.Lgauss;
                figure; plot(ndtime, field./field(1)); hold all
                plot(ndtime, vec./vec(1));
                linex(ndtime(index));
                %plot(ndtime, vec);
                %plot(ndtime(index), field(index), 'x', ...
                %     'MarkerSize', 12);
                title(run.name);
            end

            dt = ndtime(index) - ndtime(1);
            dhdt = (run.eddy.Lgauss(1) - run.eddy.Lgauss(index))./dt;

            dEdt = (TE(1) - TE(index))./TE(1)./dt;
            diags(ff) = dEdt; dhdt;

            plotx(ff) = run.topowaves; labx = 'cg (m/s)';
            %plotx(ff) = run.eddy.Ro(1)./run.bathy.S_sl; labx = 'Ro/S_\alpha';
            laby = 'dE/dt';
        end

        %%%%% topography parameter - taylor column
        if strcmpi(name, 'hogg')
            diags(ff) = 1./Ro(1) ./ ...
                (1+hsb/Lz(1) * 1/Sa);
        end

        %%%%% rest latitude hypothesis?
        if strcmpi(name, 'rest')

        end

        %%%%% estimate slope for bottom torque balance
        if strcmpi(name, 'slope est')
            [slope,pbot,angmom] = syms_angmom(run);

            sltind = find_approx(beta*angmom - pbot* alpha, 0);

            figure;
            plot(ndtime, hcen);
            hold on; plot(ndtime(sltind), hcen(sltind), 'k*');
            diags(ff) = run.traj.H;
            plotx(ff) = run.eddy.hcen(sltind);

            laby = 'Actual water depth';
            labx = 'Water depth where angmom/pbot = \alpha';
            name_points = 1;
            line_45 = 1;
        end

        %%%%% Flierl (1987) bottom torque hypothesis.
        %% estimate ∫∫ψ
        if strcmpi(name, 'btrq est')
            %plot(run.eddy.btrq(:,1)/1025);

            figure;
            subplot(211); hold all
            hplt = plot(ndtime, beta .* Lz ./f0 .* (V/Vb)*1./alpha);
            addlegend(hplt, runName);
            %try
            %    plot(ndtime, Vb./V /6);
            %catch ME
            %    plot(ndtime, Vb./V'/6);
            %end

            title(runName);
            % rhoamp = rho0 * TCOEF * run.eddy.T(:,end)';
            % %plot((run.eddy.mass-1000*run.eddy.vol) .* g .* alpha./rho0)
            % %uvec = f0 .* bsxfun(@times, run.eddy.vol, V');
            % %plot(uvec);

            %hold all
            %plot(ndtime, g*alpha*rhoamp/rho0);
            %plot(ndtime, beta.*run.eddy.Ls.*V);

            subplot(212); hold all;
            plot(ndtime, run.eddy.hcen);
            %subplot(211);
            %plot(beta .* run.eddy.voltrans)
            %hold all
            %subplot(212);
            %plot(run.eddy.btrq/1025); hold all
            %legend('Transport 1', 'Transport 2', ...
            %       'bottom torque 1', 'bottom torque 2');
            continue;
        end
        %%%%% Flierl (1987) bottom torque hypothesis.
        if strcmpi(name, 'bottom torque')

            Ro = Ro(1);
            %Lx = run.eddy.vor.dia(1)/2;
            H0 = hcen(1);
            Tamp = run.params.eddy.tamp;
            TCOEF = run.params.phys.TCOEF;

            tanhfitflag = 1;
            if tanhfitflag %|| run.params.eddy.tamp < 0
                tcrit = 1.10;
                run.fit_traj(tcrit);

                tind = run.traj.tind;
                H = run.eddy.hcen(tind); %run.traj.H;
                Y = run.eddy.my(tind); %run.traj.Y;

                titlestr = ['tanh(t/T) at t = ' num2str(tcrit) 'T'];
            else
                nsmooth = 6;
                factor = 1/3;
                [~,~,tind] = run.locate_resistance(nsmooth, factor);
                H = (run.eddy.hcen(tind));
                Y = run.eddy.my(tind) - run.bathy.xsb; ...
                    run.eddy.my(tind);
                titlestr = ['Water depth at which cross-isobath translation ' ...
                            'velocity drops by ' num2str(1-factor,2)];
            end
            if isempty(tind), continue; end

            %if H./run.bathy.hsl > 0.9
            %    H = (run.eddy.hedge(tind));
            %    disp(runName);
            %end

            %figure;
            %hplt = plot(ndtime, run.eddy.hcen); hold on
            %addlegend(hplt, runName);
            %plot(ndtime(tind), run.eddy.hcen(tind), 'k*');
            %%liney(yscl); linex([1 2 3]*tscl);

            t0 = 1; % run.eddy.tscaleind;
            titlestr = [titlestr ' | t0 = ' num2str(t0)];
            Lz = smooth(run.time(uind), run.eddy.Lgauss(uind), ...
                        round(run.eddy.turnover./(run.time(2)-run.time(1))));
            if any(Lz == 0)
                Lz = smooth(run.eddy.Lgauss, run.eddy.turnover./86400);
            end
            %if abs(run.eddy.vor.se(tind) - run.bathy.xsb) < ...
            %        run.rrdeep*0.75
            %    continue;
            %end

            diags(ff) = 1 - erf(H./Lz(t0));
            %diags(ff) = Y./(run.rrdeep);
            %plotx(ff) = Ro./Sa;
            plotx(ff) = beta/(alpha*abs(f0)/Lz(t0));
            %plotx(ff) = (hsb + Lx(t0).*alpha)./Lz(t0);
            %plotx(ff) = Lz(tind)./Lx(tind)./alpha;
            %plotx(ff) = V(1)./beta./Ls(1)^2;

            errorbarflag = 0; kozak = 1;
            name_points = 1; line_45 = 0;
            slope = num2str(round(alpha*1e3));

            if errorbarflag
                error(ff) = 2/sqrt(pi) * exp(-(H/Lz(t0))^2) * ...
                    (alpha * run.traj.yerr)/Lz(t0);
            end

            try
                if run.params.flags.conststrat == 0
                    ptName = ' N^2';
                    clr = [231,41,138]/255;
                end
            catch ME
                if run.params.eddy.tamp < 0
                    ptName = ' C';
                    clr = [117,112,179]/255;
                else
                    if run.params.phys.f0 < 0
                        ptName = ' f^{-}';
                        clr = [27,158,119]/255;
                    else
                        ptName =''; [runName];
                    end
                end
                %ptName = num2str(err,2);
            end
            % mark NS isobath runs with gray points
            if run.bathy.axis == 'x'
                clr = [1 1 1]*0.75;
            end

            laby = '$$\frac{U_b}{U_s} = 1 - \mathrm{erf}(\frac{H}{L_z^0})$$';
            labx = '$$\beta/\beta_t$$';
            %if ff == 1, hax = subplot(121); hold all; end

            % parameterization
            if ff == length(runArray.filter)
                limx = xlim;
                limy = ylim;

                xvec = linspace(0.5*min(plotx(:)), 1*max(plotx), 100);

                P = polyfit(plotx, diags, 1);
                %[P,Pint] = regress(diags', [plotx' ones(size(plotx'))], ...
                %                   0.05);
                c = P(1);

                rmse = sqrt(mean((diags - c*plotx - P(2)).^2));

                hplt = plot(xvec, c*xvec + P(2), '--', ...
                            'Color', [1 1 1]*0.75);
                hleg = legend(hplt, ['$$ \frac{U_b}{U_s} = ' ...
                                    '1 - \mathrm{erf}(\frac{H}{L_z^0}) ' ...
                                    '= ' num2str(c,3) ' \frac{\beta}{\' ...
                                    'beta_t} + ' num2str(P(2),2) '$$ ' ...
                                    '; rmse = ' num2str(rmse,3)], ...
                              'Location', 'SouthEast');
                set(hleg, 'interpreter', 'latex');

                % [y0, x1, x2, p] = fit_btrq(plotx, diags)
                % paramstr1 = ['$$\frac{' num2str(y0,2) '}{(' ...
                %             num2str(x1,2) ' + ' num2str(x2,2) ...
                %             ' (\beta / \beta_t)^{' num2str(p,2) '})}$$'];
                % yvec = y0./(x1 + x2.*xvec.^p);
                % hplt1 = plot(xvec, yvec, 'k');
                % ylim([1 2]);

                % % plot residuals
                % % figure; hold all;
                % % plot(plotx, diags - y0./(x1+x2.*plotx.^p), '*');
                % % ylabel('Residual'); xlabel('\beta/\beta_t');
                % % liney(0);

                % 45° plot
                % subplot(122);
                % insertAnnotation(annostr);
                % param1 = c*plotx;
                % rmse1 = sum(diags-param1).^2;
                % plot(diags, param1, 'k*');
                % line45;
                % xlabel(['Diagnostic $$1 - \mathrm{erf}(\frac{H}{L_z^0}) ' ...
                %         '$$'], 'interpreter', 'latex');
                % ylabel('Parameterization', 'interpreter', ...
                %        'latex');
                % beautify;
                % set(gcf, 'renderer', 'zbuffer');

                % %title(paramstr, 'interpreter', 'latex');

                % [y0, x, y1] = exp_fit(plotx, diags);
                % yvec = y1+ y0.*exp(-(xvec/x));
                % param2 = y1 + y0 * exp(-plotx./x);
                % rmse2 = sum(diags-param2).^2;
                % paramstr2 = ['$$' num2str(y1,2) ' + ' ...
                %              num2str(y0,2) ' e^{(\beta / \beta_t)/' ...
                %              num2str(x,2) '}$$'];
                % subplot(121);
                % hplt2 = plot(xvec, yvec, 'b');
                % subplot(122);
                % plot(diags, param2, 'b*');

                % hleg = legend([hplt1, hplt2], ...
                %               sprintf('%s ; rmse = %.2e', paramstr1, rmse1), ...
                %               sprintf('%s ; rmse = %.2e', paramstr2, rmse2));
                % hleg.Interpreter = 'Latex';

                % disp(['rmse (1/1+x) = ' num2str(rmse1)]);
                % disp(['rmse (exp) = ' num2str(rmse2)]);
            end

            % there is an older version that didn't really work
            %  ndtime = run.eddy.t*86400 ./ run.eddy.turnover;
            % Lx = sqrt(run.eddy.vor.lmaj .* run.eddy.vor.lmin);
            % c = smooth(run.eddy.mvx, 10)';

            % Vb = run.eddy.Vb;

            % hcen = run.eddy.hcen';

            % % last 'n' turnover periods
            % n = 30;
            % ind = find_approx(run.eddy.t, run.eddy.t(end) - ...
            %                   n * run.eddy.turnover/86400);

            % % average quantities
            % Vm = nanmean(V(ind:end));
            % Vbm = nanmean(Vb(ind:end));
            % cm = nanmean(c(ind:end));
            % Lxm = nanmean(Lx(ind:end));
            % Am = nanmean(run.eddy.vor.amp(ind:end));

            % h = run.bathy.h(1,:);
            % seind = vecfind(run.eddy.yr(1,:), run.eddy.vor.se);
            % hedge = h(seind);

            % %figure;
            % %plot(run.eddy.mx, run.eddy.my);
            % %hold on;
            % %plot(run.eddy.mx(ind), run.eddy.my(ind), 'k*');
            % %title(run.name);

            % %c = runArray.sorted_colors;

            % %num = alpha * Lx;
            % %deno = c./Vb +  V./Vb;

            % d1 = alpha .* f0./beta .* Vbm./Vm;
            % d2 = cm./Vm .* f0./beta./Lxm .* Am;
            % diags(ff) = d1/100;

            % plotx(ff) = mean((hedge(ind:end) + hcen(ind:end)) /2);
            % %hold all;
            % %hplt = plot(ndtime, vec);
            % %addlegend(hplt, run.name);
            % %plot(ndtime, run.eddy.Lgauss, 'Color', get(hplt, ...
            % %                                            'Color'))
            % %runArray.reset_colors(c);
        end

        %%%%% test critical iflux hypothesis for eddy to
        %%%%% start moving northward
        if strcmpi(name, 'critical flux')
            iflux = run.csflux.west.itrans.shelf(:,1);
            dcy = diff(run.eddy.vor.cy);

            % make sure my time vectors are the same
            assert(isequal(run.eddy.t*86400, ...
                           run.csflux.time));

            % find where velocity changes sign
            ind = find(dcy(run.csflux.tscaleind:end) > 0, ...
                       1, 'first') - 1 + run.csflux.tscaleind;

            % check ind detection with flux and center
            % location plot
            %figure;
            %plotyy(run.eddy.t, run.eddy.vor.cy, ...
            %       run.csflux.time/86400, ...
            %       run.csflux.west.shelf(:,1));
            %linex(run.eddy.t(ind));

            %run.animate_zeta(ind, 1);

            % Get Flux at ind
            run.csflux.critrans = ...
                run.csflux.west.itrans.shelf(ind,1);

            diags(ff) = run.csflux.critrans;
        end

        % nondim parameters to compare runs
        if strcmpi(name, 'diff') || strcmpi(name, 'nondim')

            if ff == 1
                close;
                disp(sprintf('| %18s | %5s | %4s | %4s | %8s | %5s |', ...
                             'name', 'Rh', 'Ro', 'bl/f', 'beta_t', ...
                             'L/Lsl'));
            end
            disp(sprintf('| %18s | %5.2f | %4.2f | %4.2f | %.2e | %5.2f |', ...
                         run.name, run.params.nondim.eddy.Rh, ...
                         Ro(1), beta*Lx(1)/f0, beta_t, ...
                         Lx(1)./run.bathy.L_slope));
            continue;
        end

        % penetration
        if strcmpi(name, 'hcen')
            hfinal = mean(hcen(tind:end));
            hinit = hcen(1);

            diag_h = (hinit - hfinal)./Lz(tind);

            diag_l = (mean(run.eddy.my(tind:end) - ...
                           xsb))./(run.eddy.vor.dia(tind)/2);

            diagstr = ['h = ' num2str(diag_h) ...
                       ' | L = ' num2str(diag_l)];
        end

        %%%%% beta v/s beta_t
        if strcmpi(name, 'betas')
            plots = 0;
            betat = Sa .* f0 ./ max(run.bathy.h(:));
            diagstr = [num2str( ...
                betabeta ./ betat  ...
                ) ' | ' num2str(mean(hcen(run.tscaleind:end)))];
        end

        %%%%% shelf flux
        if strcmpi(name, 'shelf flux')
            if ~isfield(run.csflux, 'time')
                continue;
            end
            if ff == 1
                hfig_flux = figure; hold on; hax1 = gca;
                hfig_fluxerr = figure; hold on;
            end

            ind = run.eddy.tscaleind;
            transscl = 0.075 * 9.81/f0 .* run.eddy.amp(ind).* hsb/1000;

            % flux vector for applicable time
            % convert everything to double since I'm
            % dealing with large numbers here (time in
            % seconds) and integrated flux (m^3)
            fluxvec = double(smooth(run.csflux.west.shelf(run.tscaleind: ...
                                                          end,1), 6));
            ifluxvec = double(smooth(run.csflux.west.itrans.shelf(run.tscaleind: ...
                                                              end,1), 6));
            tvec = double(run.csflux.time(run.tscaleind:end));

            % change origin
            ifluxvec = (ifluxvec - ifluxvec(1));
            tvec = (tvec - tvec(1));

            E = [ones(size(tvec))' tvec'];

            %%%%%%%%%%% See Wunsch(1996) pg. 116
            % P matrix
            x = E\ifluxvec;
            intercept = x(1);
            avgflux = x(2);
            true = ifluxvec; est = intercept + avgflux .* ...
                   (tvec-tvec(1))';
            res = true-est;
            % (E' * E) ^-1
            %ETEI = inv(E'*E);
            % from http://blogs.mathworks.com/loren/2007/05/16/purpose-of-inv/
            [Q,R] = qr(E,0);
            S = inv(R);
            ETEI = S*S';
            % assuming noise vector (res) is white
            P = ETEI * E' * var(res) * E * ETEI;
            err = sqrt(diag(P));
            err = err(2); % standard error

            %%%%%%%%%%% use MATLAB regress
            [b, bint, r, rint, stats] = ...
                regress(ifluxvec, E);
            avgflux = b(2);
            err = abs(bint(2) - b(2));

            % plot fit
            %figure; hold all;
            %plot(tvec/86400, true, '*');
            %plot(tvec/86400, est); plot(tvec/86400, res); liney(0);

            %[c,lags] = xcorr(fluxvec - mean(fluxvec(:)), 'coef');
            %plot(lags, c); linex(0); liney(0);

            %%%%%%%%%%% mean of instantaneous flux
            % find number of peaks
            %mpd = 6;
            % crests
            %[~,pl] = findpeaks(fluxvec, 'MinPeakDistance', mpd);
            % troughs
            %[~,nl] = findpeaks(-1*fluxvec, 'MinPeakDistance', mpd); ...

            % make sure peak to trough distance is not
            % smaller than mpd
            %indices = sort([pl; nl]);
            %mask = [0; diff(indices) < mpd];
            %filtered = indices(~isnan(fillnan(indices .* ~mask,0)));
            %dof = length(filtered) + 1; % (crude) degrees of freedom;

            % check dof calculation
            %figure; plot(fluxvec); linex(filtered); title(num2str(dof));pause;

            %flx = mean(max(fluxvec/1000));
            %flx = run.csflux.west.avgflux.shelf(1)/1000;
            % standard deviation
            %sdev = sqrt(1./(length(fluxvec)-1) .* sum((fluxvec - flx*1000).^2))/1000;
            % error bounds
            %errmean = abs(conft(0.05, dof-1) * sdev / sqrt(dof));
% $$$ % $$$
% $$$                     % check error bounds with itrans
% $$$                     hfig2 = figure;
% $$$                     set(gcf, 'renderer', 'opengl');
% $$$                     subplot(2,1,1);
% $$$                     plot(run.csflux.time/run.tscale, ...
% $$$                          run.csflux.west.shelf(:,1)/1000);
% $$$                     liney([flx-err flx flx+err]);
% $$$                     subplot(2,1,2);
% $$$                     plot(run.csflux.time/run.tscale, ...
% $$$                          run.csflux.west.itrans.shelf(:,1));
% $$$                     Ln = createLine(1, ...
% $$$                                    run.csflux.west.itrans.shelf(run.tscaleind,1), ...
% $$$                                    1, (flx-err)*1000*run.tscale);
% $$$                     L = createLine(1, ...
% $$$                                    run.csflux.west.itrans.shelf(run.tscaleind,1), ...
% $$$                                    1, flx*1000*run.tscale);
% $$$                     Lp = createLine(1, ...
% $$$                                    run.csflux.west.itrans.shelf(run.tscaleind,1), ...
% $$$                                    1, (flx+err)*1000*run.tscale);
% $$$                     hold on; drawLine(L);drawLine(Ln,'Color','g'); ...
% $$$                         drawLine(Lp,'Color','r');
% $$$                     limy = ylim; ylim([0 limy(2)]);
% $$$                     %pause;
% $$$                     try
% $$$                         close(hfig2);
% $$$                     catch ME; end
% $$$ % $$$
            run.eddy.paramflux = avgflux;
            diagstr = [num2str(avgflux/1000,'%.2f') '±' ...
                       num2str(err/1000,'%.2f') ' mSv | scale = ' ...
                       num2str(transscl)];

            paramerr = avgflux/1000 - transscl;
            figure(hfig_fluxerr)
            plot(run.eddy.Ro(tind), paramerr, '*');

            figure(hfig_flux);
            errorbar(transscl, avgflux/1000, err/1000, 'x');
            %plot(transscl, flx, 'x');
            text(transscl, double(avgflux + err)/1000, run.name, ...
                 'Rotation', 90, 'FontSize', 12);

            %errorbar(ff , avgflux/1000, err/1000, 'x');
            %set(hax1, 'Xtick', [1:runArray.len]);
            %lab = cellstr(get(hax1,'xticklabel'));
            %lab{ff} = runArray.getname( ff);
            %set(hax1,'xticklabel', lab);
        end

        if isempty(diagstr)
            diagstr = num2str(diags(ff));
        end

        if plots
            figure(hfig);
            axes(hax);
            if errorbarflag
                errorbar(plotx(ff), diags(ff), error(ff), 'x', ...
                         'LineWidth', 2, 'Color', clr);
            else
                plot(plotx(ff), diags(ff), '.', 'Color', clr, ...
                     'MarkerSize', 20);
            end

            % add run names
            if name_points
                text(plotx(ff)-4e-3, diags(ff), ptName, 'FontSize', ...
                     16, 'Rotation', 0, 'Color', clr);
            end
            if ff == 1
                if strfind(labx, '$$')
                    xlabel(labx, 'interpreter', 'latex');
                else
                    xlabel(labx);
                end
                if strfind(laby, '$$')
                    ylabel(laby, 'interpreter', 'latex')
                else
                    ylabel(laby);
                end
                htitle = title(titlestr);
            end
        end

        disp([run.name ' | ' name ' = ' diagstr ' | plotx ' ...
              '= ' num2str(plotx(ff))]);
    end

    if exist('sortedflag', 'var') & sortedflag
        runArray.reset_colors(cb);
    end

    if plots
        figure(hfig); ax1 = gca;
        maximize(); drawnow; pause(1);
        %beautify([20 20 22]);
        set(gcf, 'renderer', 'zbuffer');
        if line_45, line45; end

        if kozak
            ax2 = kozakscatterplot(ax1, [min(plotx) max(plotx)], ...
                             [min(diags) max(diags)]);
            grid off;

            %hleg = legend;
            %pos = hleg.Position;
            %hleg.Position = [pos(1)-0.1 pos(2:end)];
        end
        beautify([18 18 20]);

        if strcmpi(name, 'bottom torque')
            ax2.YLabel.Rotation = 90;

            pos = ax2.YLabel.Position;
            ex = ax2.YLabel.Extent;
            ax2.YLabel.Position = [pos(1)+ex(3)*1.2 pos(2:end)];
        end
    end

    if exist('hfig_flux', 'var')
        figure(hfig_flux);
        insertAnnotation(annostr);
        limy = ylim;
        ylim([0 limy(2)]);
        line45; axis square;
        ylabel('Flux (mSv)');
        xlabel('Parameterization (mSv)');
        beautify([18 18 20]);
    end
end