% animate variables at the surface and cross-section
function [] = animate_surfsection(runs, varname, t0, ntimes)

    if ~exist('ntimes', 'var'), ntimes = length(runs.time); end
    if ~exist('t0', 'var'), t0 = 1; end

    dt = 3;

    runs.video_init(['section-' varname]);
    makeVideo = runs.makeVideo;

    csfluxflag = 0;
    if csfluxflag
        isobath = 4;
        iy = runs.csflux.ix(isobath) * ones(size(runs.time));
    else
        y0 = runs.eddy.my;
        y1 = y0 - runs.eddy.vor.dia/4;
        iy = vecfind(runs.rgrid.y_rho(:,1), y0);
        iy1 = vecfind(runs.rgrid.y_rho(:,1), y1);
    end
    tt = t0;
    xr = runs.rgrid.x_rho(1,2:end-1)/1000;

    % read data here, so that I don't incur overhead at least for
    % surface fields.

    % cross-shelf dye?
    if strcmpi(varname, 'csdye')
        runs.read_csdsurf;
        varname = runs.csdname;
    end

    % eddy dye?
    if strcmpi(varname, 'eddye')
        runs.read_eddsurf;
        varname = runs.eddname;
    end

    varname1 = 'rho'; varname;

    % if different variables, do same location
    if ~strcmpi(varname1, varname), iy1 = iy; y1 = y0; end

    % process cross-shelf dye
    v = dc_roms_read_data(runs.dir, varname, ...
                          tt, {runs.bathy.axis iy(tt) iy(tt)}, ...
                          [], runs.rgrid, 'his', 'single')/1000;
    v1 = dc_roms_read_data(runs.dir, varname1, ...
                           tt, {runs.bathy.axis iy1(tt) iy1(tt)}, ...
                           [], runs.rgrid, 'his', 'single')/1000;

    v = v(2:end-1,:,:);
    v1 = v1(2:end-1,:,:);

    if strcmpi(varname1, 'rho') || strcmpi(varname1, 'dye_02')
        rback = dc_roms_read_data(runs.dir, varname1, 1, {}, [], ...
                                  runs.rgrid, 'his', 'single');
        v1 = v1*1000 - squeeze(rback(2:end-1,iy1(tt),:));
    end

    dx = 20; % start from shelfbreak - 20 km
    figure
    hax(1) = subplot(2,2,[1 2]);
    runs.makeVideo = 0;
    runs.animate_field(varname, hax, t0, 1);
    runs.makeVideo = makeVideo;
    ylim([runs.bathy.xsb/1000-dx max(ylim)])
    if ~csfluxflag
        if strcmpi(varname1, varname)
            liney([y1(tt) y0(tt)]/1000, {'1'; '2'}, 'k');
        else
            liney([y1(tt) y0(tt)]/1000, [], 'k');
        end
    else
        liney(runs.csflux.x(isobath)/1000, [], 'k');
    end
    clim = caxis;
    clim(1) = runs.bathy.xsb/1000 - dx;
    caxis(clim);

    hax(2) = subplot(2,2,4);
    x0 = runs.eddy.mx(tt)/1000;
    xvec = xr - x0;
    zvec = runs.rgrid.z_r(:, iy(tt)+1, 1);
    hplt = pcolor(xvec, zvec, v');
    hold on
    if strcmpi(varname1, 'rho')
        hrho = contour(xvec, zvec, v1', ...
                       [1 1]*runs.eddy.drhothresh(1), 'k', ...
                       'LineWidth', 2);
    end
    hl = linex([runs.eddy.rhovor.ee(tt) ...
                runs.eddy.rhovor.we(tt) x0]/1000 - x0, [], 'k');
    hly = liney(-1 * runs.eddy.Lgauss(tt), [], 'k');
    liney(-1*runs.bathy.hsb, 'shelfbreak');
    if strcmpi(varname1, varname)
        title('2')
    else
        title(varname);
    end
    shading interp;
    if ~csfluxflag, ylim([-1*min(runs.bathy.h(1,iy1)) 0]); end
    colorbar; caxis(clim);

    hax(3) = subplot(2,2,3);
    zvec1 = runs.rgrid.z_r(:, iy1(tt)+1, 1);
    hplt1 = pcolor(xvec, zvec1, v1'); hold on;
    hl1 = linex([runs.eddy.rhovor.ee(tt) ...
                 runs.eddy.rhovor.we(tt) x0]/1000 - x0, [], 'k');
    hly1 = liney(-1 * runs.eddy.Lgauss(tt), [], 'k');
    if strcmpi(varname1, 'rho')
        clim1 = caxis;
        hrho = contour(xvec, zvec, v1', ...
                       [1 1]*runs.eddy.drhothresh(1), 'k', ...
                       'LineWidth', 2);
        caxis(clim1);
        center_colorbar;
    end
    liney(-1*runs.bathy.hsb, 'shelfbreak');
    if strcmpi(varname1, varname)
        title('1')
    else
        title(varname1);
    end
    shading interp;
    if ~csfluxflag, ylim([-1*min(runs.bathy.h(1,iy1)) 0]); end
    colorbar;
    if strcmpi(varname1, varname)
        caxis(clim);
    end

    % linkaxes(hax, 'x');
    xlim([-1 1]* 200);
    linkaxes(hax([3 2]), 'xy');

    if ntimes > 1
        runs.video_update();

        for tt=t0+1:dt:ntimes
            axes(hax(1))
            cla(hax(1))
            runs.makeVideo = 0;
            runs.animate_field(varname, hax, tt, 1);
            runs.makeVideo = makeVideo;
            if ~csfluxflag
                if strcmpi(varname1, varname)
                    liney([y1(tt) y0(tt)]/1000, {'1'; '2'}, 'k');
                else
                    liney([y1(tt) y0(tt)]/1000, [], 'k');
                end
            else
                liney(runs.csflux.x(isobath)/1000, [], 'k');
            end
            ylim([runs.bathy.xsb/1000-dx max(ylim)])
            caxis(clim);

            v = dc_roms_read_data(runs.dir, varname, ...
                                  tt, {runs.bathy.axis iy(tt) iy(tt)}, ...
                                  [], runs.rgrid, 'his', 'single')/1000;
            v1 = dc_roms_read_data(runs.dir, varname1, ...
                                   tt, {runs.bathy.axis iy1(tt) iy1(tt)}, ...
                                   [], runs.rgrid, 'his', 'single')/1000;
            v = v(2:end-1,:,:);
            v1 = v1(2:end-1,:,:);

            if strcmpi(varname1, 'rho') || strcmpi(varname1, 'dye_02')
                v1 = v1*1000 - squeeze(rback(2:end-1,iy1(tt),:));
            end

            x0 = runs.eddy.mx(tt)/1000;
            xvec = xr - x0;
            zvec = runs.rgrid.z_r(:, iy(tt)+1, 1);
            zvec1 = runs.rgrid.z_r(:, iy1(tt)+1, 1);

            hplt1.CData = v1';
            hplt1.XData = xvec;
            hplt1.YData = zvec1;
            hl1{1}.XData = [1 1] * runs.eddy.vor.ee(tt)/1000 - x0;
            hl1{2}.XData = [1 1] * runs.eddy.vor.we(tt)/1000 - x0;
            hly1.YData = [1 1] * -1 * runs.eddy.Lgauss(tt);

            hplt.CData = v';
            hplt.XData = xvec;
            hplt.YData = zvec;
            hl{1}.XData = [1 1] * runs.eddy.vor.ee(tt)/1000 - x0;
            hl{2}.XData = [1 1] * runs.eddy.vor.we(tt)/1000 - x0;
            hly.YData = [1 1] * -1 * runs.eddy.Lgauss(tt);

            runs.video_update();
            pause(1);
        end
        runs.video_write();
    end
end