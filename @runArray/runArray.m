classdef runArray < handle
    properties
        % folders
        folders;
        % array of run instances
        array;
        % description
        name;
        % rotate NS track plots to align with EW?
        rotate_ns = 0;
        % sort by this parameter?
        sort_param = []; sorted = 0;
        % length of array
        len;
        % actual indices to plot
        filter = [];
    end
    methods
        % constructor
        function [runArray] = runArray(folders, name, reset)

            if ~exist('reset', 'var'), reset = 0; end

            runArray.array = runs.empty([length(folders) 0]);
            kk = 1;
            for ii = 1:length(folders)
                warning off;
                try
                    runArray.folders{kk} = ['../topoeddy/' folders{ii}];
                    runArray.array(kk) = runs(runArray.folders{kk}, ...
                                              reset);
                    disp([runArray.array(kk).name ' completed'])

                    if ~exist('name', 'var') || isempty(name)
                        runArray.name{kk} = runArray.array(kk).name;
                    else
                        runArray.name = name;
                    end

                    kk = kk + 1;
                catch ME
                    disp([folders{ii} ' did not work'])
                    disp(ME.message)
                    continue;
                end
            end
            runArray.len = kk-1;
        end

        function [] = print_names(runArray)
            for ii=1:runArray.len
                disp([num2str(ii) ' | ' runArray.array(ii).name]);
            end
        end

        % sort members of the array by runArray.sort_param;
        function [] = sort(runArray, sort_input)

            if ~exist('sort_input', 'var') || isempty(sort_input)
                error('need sort_input to sort!');
            end

            [ss,ind] = sort(sort_input, 'ascend');
            runArray.sort_param = sort_input;

            % sort arrays
            runArray.array = runArray.array(ind);

            % sort names
            for ii = 1:length(ind)
                names{ii} = runArray.name{ind(ii)};
            end
            runArray.name = names;

            runArray.sorted = 1;

            disp(['runArray sorted.']);
        end

        % helper function for setting line colors when plotting
        % diagnostics from a sorted runArray object
        function [corder_backup] = sorted_colors(runArray)
            corder_backup = get(0, 'DefaultAxesColorOrder');
            if runArray.sorted
                if isempty(runArray.filter)
                    len = runArray.len;
                else
                    len = length(runArray.filter);
                end

                set(0, 'DefaultAxesLineStyleorder','-');
                set(0, 'DefaultAxesColorOrder', brighten(cbrewer('seq','Reds',len), ...
                                                         -0.5));
            end
        end

        function [] = reset_colors(runArray, corder_backup)
            if runArray.sorted
                set(0, 'DefaultAxesColorOrder', corder_backup);
                set(0,'DefaultAxesLineStyleOrder',{'-','--','-.'});
            end
        end

        function [] = test_hashes(runArray)
            for ii=1:runArray.len
                if ~strcmpi(runArray.array(ii).csflux.hash, ...
                    'ee34764138b91a2d150b58c7791bc60d480847e1')
                    if ~strcmpi(runArray.array(ii).csflux.hash, ...
                                '2a76dc848f7ca33a4d6953ce79451e72293c72ee')
                        warning([runArray.array(ii).name ' does not ' ...
                                 'have most recent flux ' ...
                                 'calculated']);
                    end
                end
            end
        end

        function [] = print_params(runArray, command)
            for ii=1:runArray.len
                run = runArray.array(ii);
                out = eval(['run.' command]);
                if ~ischar(out)
                    out = num2str(out);
                end
                disp([runArray.array(ii).name ' | ' out]);
            end
        end

        function [] = plot_energy(runArray)

            hfig1 = figure;
            insertAnnotation(['runArray.plot_energy']);

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff = 1:length(runArray.filter)
                ii = runArray.filter(ff);

                run = runArray.array(ii);
                name = runArray.getname(ii);

                ndtime = run.eddy.t * 86400 ./ run.eddy.turnover;

                try
                    subplot(2,1,1); hold all
                    hplt = plot(ndtime, run.eddy.KE);
                    title('KE');
                    addlegend(hplt, name);

                    subplot(2,1,2); hold all
                    plot(ndtime, (run.eddy.PE - run.eddy.PE(end)));
                    title('PE');
                catch ME
                end
            end

            subplot(211); linex(1);
            subplot(212); limy = ylim; ylim([0 limy(2)]);
        end

        function [] = plot_param(runArray)
            hfig1 = figure;
            insertAnnotation(['runArray.plot_param']);
            hold all
            hfig2 = figure;
            insertAnnotation(['runArray.plot_param']);
            hold all

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);

                run = runArray.array(ii);
                if isempty(runArray.name)
                    name = run.name;
                else
                    name = runArray.name{ii};
                end
                eddy_ndtime = run.eddy.t/run.tscale*86400;
                csflx_ndtime = run.csflux.time/run.tscale * 86400;
                etind = find_approx(eddy_ndtime, 1.0, 1);
                cstind = find_approx(csflx_ndtime, 1.0, 1);

                etind = run.tscaleind;

                meanprox(ii) = nanmean(run.eddy.hcen(etind:end));
                meanflux(ii) = nanmean(run.csflux.west.shelf(cstind: ...
                                                             end));
                meanLz(ii) = nanmean(run.eddy.Lgauss(1));
                meancy(ii) = nanmean(run.eddy.cy(etind:end));

                param(ii) = (run.eddy.Ro(1)/ run.params.nondim.S_sl);

                x = (meanprox(ii));
                y = meanLz(ii) * sqrt(abs(log(param(ii))));

                figure(hfig1);
                hgplt = plot(x, y, '.', 'MarkerSize', 16);
                addlegend(hgplt, name);
                disp(['run = ', run.name , ' | mean prox. = ', ...
                      num2str(meanprox(ii))]);
                %    pause;

                figure(hfig2);
                hgplt = plot(param(ii), meanprox(ii), '.', 'MarkerSize', ...
                             16);
                text(param(ii), meanprox(ii), run.name)
            end
            figure(hfig1);
            ylabel('Water depth at eddy center (m)');
            xlabel('Parameterization (m) : H = D * sqrt(ln(Ro/S_\alpha))');
            axis square;
            line45;
            beautify([18 18 20]);
            %figure(hfig2);
            %ylabel('meandist flux');
            %xlabel('Slope parameter, Ro/S');

        end

        function [] = streamerstats(runArray)

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);

                run.plot_velsec([run.tscale/86400:50:run.time(end)/86400]);

            end
        end

        function [] = plot_jetprops(runArray)
            figure;
            ax = gca; hold all;
            insertAnnotation('runArray.jetprops');
            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);

                ndtime = run.eddy.t*86400 ./ run.csflux.tscale;

                hplot = plot(ndtime, run.jet.vscale);
                addlegend(hplot, run.name);
            end
            linkaxes(ax, 'x');
            xlim([0 4])
        end

        function [] = plot_test1(runArray)
            hfig = figure;
            ax1 = subplot(211); hold all;
            ax2 = subplot(212); hold all;

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            if runArray.sorted
                subplot(211);
                co = runArray.sorted_colors;
                subplot(212);
                co = runArray.sorted_colors;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = run.name;

                ndtime = run.eddy.t * 86400./ (run.eddy.turnover);
                tind = 1:ceil(50*run.eddy.turnover/86400);

                beta = run.params.phys.beta;
                Ldef = run.rrdeep;

                dEdt = smooth(diff((run.eddy.KE + run.eddy.PE)./run.eddy.vol)./ ...
                       diff(run.eddy.t*86400), 14);
                ndtime1 = avg1(ndtime);

                [~,~,rest] = run.locate_resistance;
                tinds = [run.eddy.tscaleind run.eddy.edgtscaleind rest];
                axes(ax1)
                hplot = plot(ndtime1, dEdt);
                %figure;
                %hplot = plot(ndtime, run.eddy.cvx * 1000/86400);
                addlegend(hplot, name);
                plot(ndtime1(tinds), dEdt(tinds), 'k*');
                %liney(-beta .* Ldef^2);
                %linex(ndtime(run.tscaleind));
                %pause();

                axes(ax2)
                plot(ndtime, run.eddy.KE);
                plot(ndtime(tinds), run.eddy.KE(tinds), 'k*');
            end
            axes(ax1); liney(0);
            axes(ax2); liney(0);

            insertAnnotation('runArray.plot_test1');
            beautify;

            if runArray.sorted
                runArray.reset_colors(co);
            end
        end

        function [] = plot_Rosurf(runArray)
            hfig = figure;
            ax = gca; hold all;

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);

                if isempty(run.vorsurf)
                    run.calc_vorsurf;
                end

                name = run.name;
                ndtime = run.eddy.t * 86400./ (run.eddy.turnover);
                tind = 1:length(ndtime);

                Ro = avg1(avg1(bsxfun(@rdivide, run.vorsurf, ...
                                      avg1(avg1(run.rgrid.f', 1), ...
                                           2)),1),2);

                Ro = Ro .* run.eddy.vormask;

                iy = vecfind(run.rgrid.y_rho(:,1), run.eddy.my);
                fcen = run.rgrid.f(iy,1);
                pv = fcen./run.eddy.Lgauss' .* (1+run.eddy.Ro');
                hplot = plot(pv./pv(1));

                Romin = squeeze(min(min(Ro,[],1),[],2));
                %hplot = plot(ndtime, Romin./Romin(1));
                addlegend(hplot, name);
            end

            ylabel('min(vorticity/f)');
            xlabel('Time / turnover time');
            insertAnnotation('runArray.plot_test1');
            beautify;
        end

        function [] = plot_test2(runArray)

            % figure;
            % hold all;

            %corder_backup = runArray.sorted_colors;

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = runArray.name{ii};
                ndtime = run.eddy.t*86400 / run.eddy.turnover;

                figure;
                subplot(211); hold all
                plot(ndtime, run.bottom.pbtorque);
                plot(ndtime, run.angmom.sym_betatrq);
                title(name);
                legend('pbot','\beta');
                subplot(212)
                plot(ndtime, run.eddy.cvy*1000/86400);
                liney(0);
                linex(ndtime(run.traj.tind));
            end

            %runArray.reset_colors(corder_backup);
        end

        function [] = plot_test3(runArray)
            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            figure; hold all

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = runArray.getname(ii);

                hplt = plot(run.ndtime, ...
                            (run.eddy.Ro));

                addlegend(hplt, name);
            end
        end

        function [] = plot_spectra(runArray)
            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            figure; hold all

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = runArray.getname(ii);


                % find sponge edges
                sz = size(run.sponge);
                sx1 = find(run.sponge(1:sz(1)/2,sz(2)/2) == 0, 1, 'first');
                sx2 = sz(1)/2 + find(run.sponge(sz(1)/2:end,sz(2)/2) == 1, 1, ...
                                     'first') - 2;
                sy2 = find(run.sponge(sz(1)/2, :) == 1, 1, 'first') - 1;

                % indices to look at
                % west, then east
                ix = [sx1 + 10; sx2 - 10];
                iy = [sy2 - 10; sy2 - 10];

                for nn=1:length(ix)
                    u = dc_roms_read_data(run.dir, 'u', [], {'x' ix(nn) ix(nn); ...
                                        'y' iy(nn) iy(nn); 'z' 72 72}, ...
                                          [], run.rgrid, 'his', 'single');

                    v = dc_roms_read_data(run.dir, 'v', [], {'x' ix(nn) ix(nn); ...
                                        'y' iy(nn) iy(nn); 'z' 72 72}, ...
                                          [], run.rgrid, 'his', 'single');

                    [t,iu,~] = unique(run.time, 'stable');

                    inertialfreq = run.params.phys.f0/2*pi;
                    [psi, lambda] = sleptap(length(iu));
                    [F,S] = mspec(1/2*(u(:,iu).^2 + v(:,iu).^2)', ...
                                  psi);
                    % fourier frequencies so that Nyquist is at 1
                    f = fourier(86400, length(iu))/2*pi;

                    hgplt = loglog(f./inertialfreq, S(:,end));
                    set(gca, 'XScale', 'log');
                    set(gca, 'YScale', 'log');
                    addlegend(hgplt, [name ' | ' num2str(ix(nn))]);
                end
            end
            linex(1);
        end

        function [] = plot_envelope(runArray)
            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            figure; hold all

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = runArray.getname( ii);

                env = run.csflux.west.shelfwater.envelope;
                tind = 1;
                diagnostic = mean(run.bathy.xsb - env(tind:end));

                if run.bathy.sl_shelf ~= 0
                    beta = run.params.phys.f0 ./ max(run.bathy.h(:)) * ...
                           run.bathy.sl_shelf;
                else
                    beta = Inf; run.params.phys.beta;
                end
                param = sqrt(0.075*run.eddy.V(1)./beta);

                hgplt = plot(run.csflux.time(tind:end)/run.tscale, ...
                             (run.bathy.xsb - env(tind:end))./run.rrshelf);
                %hgplt = plot(param, diagnostic, '*');
                addlegend(hgplt, name, 'NorthWest');
           end

           for ff=1:length(runArray.filter)
               ii = runArray.filter(ff);
               run = runArray.array(ii);
               name = runArray.getname( ii);
               if run.bathy.sl_shelf ~= 0
                   beta = run.params.phys.f0 ./ max(run.bathy.h(:)) * ...
                           run.bathy.sl_shelf;
               else
                   beta = Inf; run.params.phys.beta;
               end
               Ly = sqrt(0.075*run.eddy.V(1)./beta)./run.rrshelf;
               liney(Ly, run.name);
           end
           %axis square; line45;
           beautify([18 18 20]);
        end

        function [] = plot_enflux(runArray)

            corder_backup = runArray.sorted_colors;

            figure;
            hold all

            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);

                ndtime = run.asflux.time / run.eddy.turnover;

                filter = 'topo.';
                eval(['teflux = run.asflux.' filter 'ikeflux(:,3) + ' ...
                      'run.asflux.' filter 'ipeflux(:,3)' ...
                      '- run.asflux.' filter 'ikeflux(:,2) - ' ...
                      'run.asflux.' filter 'ipeflux(:,2);']);
                hgplt = plot(ndtime, teflux);
                addlegend(hgplt, run.name);
            end
            liney(0);
            runArray.reset_colors(corder_backup);
        end

        function [] = plot_fluxcor(runArray)
            if isempty(runArray.filter)
                runArray.filter = 1:runArray.len;
            end

            for ff=1:length(runArray.filter)
                ii = runArray.filter(ff);
                run = runArray.array(ii);
                name = runArray.getname( ii);

                %vec1 = run.eddy.vor.lmaj(run.tscaleind:end)./ ...
                %       run.eddy.vor.lmin(run.tscaleind:end);
                vec1 = run.eddy.vor.lmaj(run.tscaleind:end);
                vec2 = run.csflux.west.shelf(run.tscaleind:end);

                vec1 = vec1 - mean(vec1);
                vec2 = vec2 - mean(vec2);

                [c,lags] = xcorr(vec1, vec2, 'coef');
                corrcoef(vec1, vec2)
                dt = (run.csflux.time(2)-run.csflux.time(1))/86400;

                figure;
                subplot(2,1,1)
                plot(run.eddy.t(run.tscaleind:end)*86400./run.tscale, ...
                     smooth(vec1,4)./max(vec1));
                hold on
                plot(run.csflux.time(run.tscaleind:end)/run.tscale, ...
                     vec2./max(vec2), 'Color', [1 1 1]*0.75);
                subplot(2,1,2)
                plot(lags * dt,c);
                xlabel('Lag (days)');
                linex(0); liney(0);
            end
        end

        function [name] = getname(runArray, ii)
            if isempty(runArray.name)
                name = runArray.array(ii).name;
            else
                name = runArray.name{ii};
            end
        end
    end
end
