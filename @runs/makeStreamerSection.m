% makes streamer mask for numerical parameterization
function [v, mask] = makeStreamerSection(runs, isobath, maxloc, V0, L0, Lz0)

    debug = 0;
    circle_kink = 0;

    if ~exist('maxloc', 'var') || isempty(maxloc)
        [~,maxloc] = runs.calc_maxflux(isobath);
    end

    if ~exist('V0', 'var') || isempty(V0)
        V0 = runs.eddy.rhovor.Vke(maxloc);
    end

    if ~exist('L0', 'var') || isempty(L0)
        L0 = median(runs.eddy.rhovor.dia(1:maxloc))/2;
    end

    if ~exist('Lz0', 'var') || isempty(Lz0)
        Lz0 = runs.eddy.Lgauss(maxloc);
    end

    zvec = runs.csflux.vertbins(:, isobath);
    xvec = (runs.rgrid.x_rho(1,2:end-1) - runs.eddy.mx(maxloc));

    % normalized grid matrices to create mask
    [xmat, zmat] = ndgrid(xvec/L0, zvec/Lz0);

    R = runs.csflux.R;
    yoR = runs.csflux.ndloc(isobath); % y/R - used in csflux
    y0oL =  R/L0 * (1 - yoR); % y0/L - used in derivation
    xfrac = sqrt(1 - y0oL^2);
    %y0oL = (runs.eddy.my(maxloc) - runs.csflux.x(isobath))/L0;

    v = -2.3 * V0 * xmat .* exp(-xmat.^2) .* (1-erf(-zmat));

    [width, zpeak] = runs.predict_zpeak(isobath, 'use');
    width = abs(width/Lz0); zpeak = abs(zpeak/Lz0);

    if circle_kink
        kzrad = width/2; % kink radius - z
        kxrad = kzrad; % kink radius - x
        x0 = -xfrac-kxrad; -xfrac-kxrad;
        z0 = -1 * width/3;
    end
    xline = 0; -xfrac;

    a = 2;
    if ~isreal(xfrac)
        % complex xfrac -- cannot be trusted
        % make the kink (semi-circle) intersect the eddy contour
        xfrac = sqrt(1 - (width)^2);
        x0 = -xfrac;
        xline = 0;
    end

    if abs(runs.csflux.x(isobath) - runs.bathy.xsb) < 2000
        % if close to shelfbreak use barotropic mask
        % account for sloping shelf by integrating only
        % to Rhines length scale (L_β). This needs to be
        % normalized by L0, of course.
        if runs.bathy.sl_shelf ~= 0
            betash = runs.params.phys.f0/runs.bathy.hsb * runs.bathy.sl_shelf;
            Lbeta = sqrt(V0/betash) / L0;

            if Lbeta > 1
                % for gentle slopes, I shouldn't do anything.
                Lbeta = 0;
            end
        else
            Lbeta = 0;
        end
        mask = xmat < (-Lbeta);

        % xline = -Lbeta;
    else
        eddymask = ((xmat.^a + zmat.^a) > 1.0^a) .* (zmat < -width);
        if circle_kink
            kinkmask = (((xmat-x0)/kxrad).^2 + ((zmat-z0)/kzrad).^2) <= 1;
        else
            kinkmask = ((xmat.^a + zmat.^a) > 0.7^a) .* (zmat >= -width);
        end
        mask = (xmat < xline) & (eddymask | kinkmask);
    end

    if debug
        figure;
        pcolorcen(xmat, zmat, v);
        center_colorbar;
        hold on
        try
            contour(xmat, zmat, kinkmask, 'k');
            contour(xmat, zmat, eddymask, 'r');
            linex(xline);
        catch ME
        end
        contour(xmat, zmat, mask, 'b');
        keyboard;
    end
end
