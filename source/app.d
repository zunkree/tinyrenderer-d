import utga;
import std.math;
import std.stdio;
import std.algorithm;
import wavefront.obj;
import core.stdc.stdlib: rand;


const TGAColor white = TGAColor(255, 255, 255, 255);
const TGAColor red   = TGAColor(255, 0,   0,   255);
const TGAColor green = TGAColor(0, 255, 0, 255);
const int width  = 2048;
const int height = 2048;
Model model;


void line(int x0, int y0, int x1, int y1, TGAImage image, TGAColor color) {
	auto steep = false;
	if (abs(x0 - x1)<abs(y0 - y1)) {
		swap(x0, y0);
		swap(x1, y1);
		steep = true;
	}
	if (x0>x1) {
		swap(x0, x1);
		swap(y0, y1);
	}
	int dx = x1 - x0;
	int dy = y1 - y0;
	int derror2 = abs(dy) * 2;
	int error2 = 0;
	int y = y0;
	for (int x=x0; x<=x1; x++) {
		if (steep) {
			image.set(y, x, color); // if transposed, de-transpose
		} else {
			image.set(x, y, color);
		}
		error2 += derror2;

		if (error2>dx) {
			y += (y1>y0?1:-1);
			error2 -= dx*2;
		}
	}
}


void line(Vec2i p0, Vec2i p1, TGAImage image, TGAColor color) {
	bool steep = false;
	if (abs(p0.x-p1.x)<abs(p0.y-p1.y)) {
		swap(p0.x, p0.y);
		swap(p1.x, p1.y);
		steep = true;
	}
	if (p0.x>p1.x) {
		swap(p0, p1);
	}
	
	for (int x=p0.x; x<=p1.x; x++) {
		float t = (x-p0.x)/cast(float)(p1.x-p0.x);
		int y = cast(int)(p0.y*(1.-t) + p1.y*t);
		if (steep) {
			image.set(y, x, color);
		} else {
			image.set(x, y, color);
		}
	}
}


void triangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage image, TGAColor color) {
	if (t0.y>t1.y) swap(t0, t1);
	if (t0.y>t2.y) swap(t0, t2);
	if (t1.y>t2.y) swap(t1, t2);

	auto total_height = t2.y-t0.y;
	for (int i=0; i<total_height; i++) {
		auto second_half = i>t1.y-t0.y || t1.y==t0.y;
		auto segment_height = second_half ? t2.y-t1.y : t1.y-t0.y;
		auto alpha = cast(float)i/total_height;
		auto beta  = cast(float)(i-(second_half ? t1.y-t0.y : 0))/segment_height; // be careful: with above conditions no division by zero here
		Vec2i A =               t0 + (t2-t0)*alpha;
		Vec2i B = second_half ? t1 + (t2-t1)*beta : t0 + (t1-t0)*beta;
		if (A.x>B.x) swap(A, B);
		for (int j=A.x; j<=B.x; j++) {
			image.set(j, t0.y+i, color); // attention, due to int casts t0.y+i != A.y
		}
	}
}


int main(string[] args)
{
	if (args.length == 2){
		model = new Model(args[1]);
	}
	else {
		model = new Model("obj/african_head.obj");
	}
	
	auto image = new TGAImage(width, height, TGAImage.Format.RGB);
	auto light_dir = Vec3f(0,0,-1);
	foreach (face; model.faces.sort!("a[2]>b[2]")) {
		Vec2i[3] screen_coords;
		Vec3f[3] world_coords;
		for (int j=0; j<3; j++) {
			Vec3f v = model.vert(face[j]);
			screen_coords[j] = Vec2i(cast(int)((v.x+1.)*width/2.), cast(int)((v.y+1.)*height/2.));
			world_coords[j] = v;
		}
		auto n = (world_coords[2]-world_coords[0])^(world_coords[1]-world_coords[0]);
		n.normalize;
		auto intensity = n*light_dir;
		if (intensity > 0)
			triangle(screen_coords[0], screen_coords[1], screen_coords[2], image,
				     TGAColor(cast(ubyte)(intensity*255), cast(ubyte)(intensity*255), cast(ubyte)(intensity*255), 255));
	}
	image.flip_vertically();
	image.write_tga_file("output.tga");

	return 0;
}