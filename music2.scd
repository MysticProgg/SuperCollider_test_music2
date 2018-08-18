
(
var numrecursions = 4;
var coefficients = [0.3,-0.2,0.5,0.7,-0.9].normalizeSum*2; //0.25*[1+(3.sqrt),3+(3.sqrt),3-(3.sqrt),1-(3.sqrt)]; //Daubechies-4[0.3,-0.2,0.5,0.7,-0.9,0.3,0.2,-0.2].normalizeSum*2;
//var coefficients = [0.3,-0.2,0.5,0.7,-0.9,0.5,0.42,-0.7].normalizeSum*2;
//var coefficients = [0.5,0.42,-0.7].normalizeSum*2;
var arraysource;
var arraysize =1024;
var graphicstoaudiomult = 2;
var wavetablesize = arraysize*graphicstoaudiomult; // 4096;
var sizefactor = (coefficients.size-1)/arraysize;
var sizefactorreciprocal = sizefactor.reciprocal;
var rfunc;
var arraynow;
var synthesistype = 1;
var temp, temp2;

//temporal
if(synthesistype ==0) {

	//wavetable synthesis
	b = Buffer.alloc(s,wavetablesize,1).zero;

	a = { Pan2.ar(Osc.ar(b,MouseX.kr(1,100,'exponential')) * 0.1, 0.0);  }.play;


	} {

	//spectral

	//FFT filterbank controlled by dilation plot

	b = Buffer.alloc(s,wavetablesize,1).zero;

	a = {

		var inA, chainA, chain;
		inA = WhiteNoise.ar(0.1);
		chainA = FFT(LocalBuf(wavetablesize), inA);
		chain = PV_MagMul(chainA, b);
		Out.ar(0, 0.5 * IFFT(chain).dup);

	}.play;


};




//gradual change to source waveform reflects in gradual changes to dilation solution?
arraysource = {|i| i/arraysize; }!arraysize;
//arraysource = {|i| 1.0.rand; }!arraysize;
//arraysource = {|i| 1.0}!arraysize;


arraynow = arraysource.copy;

rfunc = {|array|

	numrecursions.do{


		array = array.collect{ |val2,j|
			var pos = j* sizefactor;
			var summation = 0.0;

			coefficients.do{|val,i|
				var posnow = 2*pos - i;  //dilation equation summand
				var index = (sizefactorreciprocal*posnow).round(1.0).asInteger;
				var valnow;

				if((index>=0) && (index<arraysize)) {
					valnow = (array[index])*val; //(coefficients[i]);

					//[index,array[index],valnow,coefficients[i]].postln;

					summation = summation + valnow;
				}

			};

			summation
		};

	};

	array = array/(array.abs.maxItem);


	array
};



w = Window("dilationTest", Rect(100, 200, arraysize, 300)).front;

w.view.background_(Color.black);

w.drawHook = { |v|

	//Pen.fillColor = Color.blue;
	Pen.strokeColor = Color.blue;
	Pen.moveTo(0@150);

	arraynow.do{|val,i|

		Pen.lineTo(i@(val*150 + 150));

	};

	Pen.stroke;

};




f = {

	inf.do{
		//var target = 1.0.rand2;
		//var indextarget = coefficients.size.rand;
		//var target2 = 1.0.rand2;
		//var indextarget2 = coefficients.size.rand;
		var target = {1.0.rand2}!(coefficients.size);
		var target2 = {1.0.rand2}!(coefficients.size);



		numrecursions = [4,rrand(1,10)].choose;

		100.do {|j|
			var proportion = (j/100.0);

			//coefficients[indextarget] = target*proportion;
			//coefficients[indextarget2] = target2*proportion;

			coefficients = ((1.0-proportion)*target) + (proportion*target2);


			arraysource = {|i| var interp = i/arraysize;  (((1.0-interp)*1.0) + (interp*proportion));  }!arraysize;


			arraynow = rfunc.(arraysource.copy);


			//if(j%10==1) {arraynow.postln;};


			//coefficients[1] = 0.0-(j/400.0);
			//
			//	coefficients[3] = (j/400.0).neg;
			//

			{w.refresh; }.defer;

			//1024/44100

			//(arraysize/(s.sampleRate)).wait;


			if(synthesistype ==1) {

				b.sendCollection(Signal.newFrom(arraynow).asWavetable);
				} {

				//mag phase data
				//temp = Array.fill(wavetablesize,{|i| if(i%2==0,{temp2 = 0.5*(arraynow[i.div(2)]+1.0);   temp2*temp2},{0.0});  });
				temp = Array.fill(wavetablesize,{|i| if(i%2==0,{temp2 = abs(arraynow[i.div(2)]);   temp2*temp2},{0.0});  });

				b.sendCollection(temp);
			};

			(wavetablesize/(s.sampleRate)).wait;
		};

	}

}.fork;


w.onClose = { f.stop; a.free; b.free; };

)






