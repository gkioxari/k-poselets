function showboundsandscores(im, bounds, scores)
% showboxes(im, boxes)
% Draw boxes on top of image.
boxes=bounds;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);

image(im); axis equal; hold on;

x1 = boxes(:,1);
y1 = boxes(:,2);
x2 = boxes(:,3);
y2 = boxes(:,4);
line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','color','r','linewidth',4);

for i=1:size(boxes,1)
	text(x1(i)+4,y1(i)+4, sprintf('%f',scores(i)),'BackgroundColor',[1 1 1]);
end

drawnow;
set(gca, 'xtick', []);
set(gca, 'ytick', []);
hold off;
