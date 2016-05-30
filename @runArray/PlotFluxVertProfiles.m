function [handles] = PlotFluxVertProfiles(runArray)

    isobath = 1;

    figure; maximize;
    insertAnnotation('runArray.PlotFluxVertProfiles');
    handles.hax(1) = subplot(121); hold on;
    handles.hax(2) = subplot(122); hold on;

    phio = runArray.print_params('bathy.hsb./(V0./bathy.S_sh/sqrt(phys.N2))');
    runArray.sort(phio);
    phio = runArray.print_params('bathy.hsb./(V0./bathy.S_sh/sqrt(phys.N2))');

    corder_backup = runArray.sorted_colors;

    kk = 1;
    axes(handles.hax(1));
    for ii=1:length(runArray.array)
        run = runArray.array(ii);

        hsb = run.bathy.hsb;

        if run.params.misc.rdrg ~= 0
            continue;
        end

        [start, stop] = run.flux_tindices(run.csflux.off.slope(:,1,1));
        offflux = run.csflux.off.slopeztneg(:,start:stop,1,1);
        zivec = run.csflux.vertbins(:,isobath);
        profile = trapz(run.csflux.time(start:stop)*86400, ...
                        offflux, 2);
        profile = profile./max(abs(profile));

        legstr1{kk} = num2str(phio(ii), '%.2f');
        handles.hplt1(kk) = plot(profile, zivec./hsb);
        if run.bathy.sl_shelf == 0
            handles.hplt1(kk).Color = [1 1 1]*0;
            hflat(1) = handles.hplt1(kk);
        end
        kk = kk+1;
    end

    % phii = runArray.print_params('(bathy.hsb./(V0./bathy.S_sl/sqrt(phys.N2)))');
    % chi = runArray.print_params(['(2/sqrt(pi)*exp(-(bathy.hsb/Lz0)^2)) *' ...
    %                     'V0/Lz0/(bathy.S_sl*sqrt(phys.N2))']);

    % runArray.sort(phii);
    % phii = runArray.print_params('(bathy.hsb./(V0./bathy.S_sl/sqrt(phys.N2)))');

    % chi = runArray.print_params(['(2/sqrt(pi)*exp(-(bathy.hsb/Lz0)^2)) *' ...
    %                     'V0/Lz0/(bathy.S_sl*sqrt(phys.N2))']);

    ssl = runArray.print_params('bathy.S_sl');
    runArray.sort(ssl);
    ssl = runArray.print_params('bathy.S_sl');

    set(handles.hax(2), 'ColorOrder', ...
                      brighten(cbrewer('seq', 'Blues', runArray.len), -0.6));
    kk = 1;
    axes(handles.hax(2)); hold on;
    for ii=1:length(runArray.array)
        run = runArray.array(ii);

        if run.params.misc.rdrg ~= 0
            continue;
        end

        hsb = run.bathy.hsb;

        [start, stop] = run.flux_tindices(run.csflux.on.slope(:,1,1), 0.2, 0.9);
        onflux = run.csflux.on.slopezt(:,start:stop,1,1);
        zivec = run.csflux.vertbins(:,isobath);
        profile = trapz(run.csflux.time(start:stop)*86400, ...
                        onflux, 2);
        profile = abs(profile./max(abs(profile)));
        %        profile = profile./profile(end);

        % legstr2{kk} = ['(' num2str(phii(ii), '%.1f') ...
        %               ', ' num2str(chi(ii), '%.2f') ')'];

        legstr2{kk} = num2str(ssl(ii), '%.1f');
        handles.hplt2(kk) = plot(profile, zivec./hsb);
        if run.bathy.sl_shelf == 0
            handles.hplt2(kk).Color = [1 1 1]*0;
            hflat(2) = handles.hplt2(kk);
        end
        kk = kk+1;
    end

    legfontsize = 20;

    axes(handles.hax(1));
    set(gca, 'XAxisLocation', 'Top');
    liney(-1);%ylim([-1 0]);
    limx = xlim;
    xlim([0 limx(2)]);
    xlabel('a) Shelf water outflow (m^2/s)');
    ylabel('Z / H_{sb}');
    axis square;
    beautify;
    handles.hleg(1) = columnlegend(2, legstr1, 'FontSize', legfontsize, 'Location', 'NorthWest');
    handles.hleg(1).Position(1) = 0.15;
    handles.hleg(1).Position(2) = 0.23;
    handles.htxt(1) = text(0.23, -0.08, '\phi_o');

    axes(handles.hax(2));
    set(gca, 'XAxisLocation', 'Top');
    liney(-1);
    limx = xlim;
    xlim([0 limx(2)]);
    xlabel('b) Eddy & slope water inflow (m^2/s)');
    handles.hax(2).YTickLabels = {};
    axis square;
    beautify;
    linkaxes(handles.hax, 'y');
    handles.hax(2).Position(1) = 0.5;
    handles.hleg(2) = columnlegend(2, legstr2, 'FontSize', legfontsize);
    handles.hleg(2).Position(1) = 0.77;
    handles.hleg(2).Position(2) = 0.065;
    %handles.htxt(2) = text(0.95, -0.5, '(\phi_i, \chi)');
    handles.htxt(2) = text(0.95, -0.5, 'S_{sl}');

    hflat(1).LineWidth = 4;
    hflat(2).LineWidth = 4;
    uistack(hflat(1), 'top');
    uistack(hflat(2), 'top');
end
