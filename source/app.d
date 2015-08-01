import utga;
import std.math;
import std.stdio;
import std.algorithm;
import wavefront.obj;


const TGAColor white = TGAColor(255, 255, 255, 255);
const TGAColor red   = TGAColor(255, 0,   0,   255);
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


int main(string[] args)
{
	if (args.length == 2){
		model = new Model(args[1]);
	}
	else {
		model = new Model("obj/african_head.obj");
	}

	auto image = new TGAImage(width, height, TGAImage.Format.RGB);
	for (int i=0; i<model.nfaces; i++) {
		auto face = model.face(i);
		for (int j=0; j<3; j++) {
			Vec3f v0 = model.vert(face[j]);
			Vec3f v1 = model.vert(face[(j+1)%3]);
			int x0 = cast(int)((v0.x+1.)*width/2.);
			int y0 = cast(int)((v0.y+1.)*height/2.);
			int x1 = cast(int)((v1.x+1.)*width/2.);
			int y1 = cast(int)((v1.y+1.)*height/2.);
			line(x0, y0, x1, y1, image, white);
		}
	}
	image.flip_vertically();
	image.write_tga_file("output.tga");

	return 0;
}