function showkeypoints(im,coords)

% stick figure
line_ks = [ 13 14;
            13 17;
            14 17;
            1 2;
            2 3;
            4 5;
            5 6;
            7 8;
            8 9;
            10 11;
            11 12];

image(im); axis equal; hold on;
for li = 1:size(line_ks,1)
    line(coords(line_ks(li,:),1),coords(line_ks(li,:),2),'Color','r','LineWidth',3); hold on;
end

drawnow;
set(gca, 'xtick', []);
set(gca, 'ytick', []);
hold off;

