//============================================================================
// Name        : c_SHA256_Optimizing.cpp
// Author      : Ulrich Habel, DF4IAH
// Version     :
// Copyright   : (c) 2016 by Ulrich Habel
// Description : Hello World in C++, Ansi-style
//============================================================================

// C header files
#include <stdio.h>
#include <stdlib.h>

// C++ header files
#include <iostream>

using namespace std;


int main() {
	char* buf = (char*) malloc(1024 * 1024 * 1024);
	string*  k[64]; // constants
	string*  w[64]; // working
	string* hx[ 8]; // 256 bit hash value
	string* in[64]; // in message
	string* a;
	string* b;
	string* c;
	string* d;
	string* e;
	string* f;
	string* g;
	string* h;


	/* INIT section */

	hx[0] = new string("h0_0x6a09e667");
	hx[1] = new string("h1_0xbb67ae85");
	hx[2] = new string("h2_0x3c6ef372");
	hx[3] = new string("h3_0xa54ff53a");
	hx[4] = new string("h4_0x510e527f");
	hx[5] = new string("h5_0x9b05688c");
	hx[6] = new string("h6_0x1f83d9ab");
	hx[7] = new string("h7_0x5be0cd19");

	k[ 0] = new string("k00_0x428a2f98");
	k[ 1] = new string("k01_0x71374491");
	k[ 2] = new string("k02_0xb5c0fbcf");
	k[ 3] = new string("k03_0xe9b5dba5");
	k[ 4] = new string("k04_0x3956c25b");
	k[ 5] = new string("k05_0x59f111f1");
	k[ 6] = new string("k06_0x923f82a4");
	k[ 7] = new string("k07_0xab1c5ed5");
	k[ 8] = new string("k08_0xd807aa98");
	k[ 9] = new string("k09_0x12835b01");
	k[10] = new string("k10_0x243185be");
	k[11] = new string("k11_0x550c7dc3");
	k[12] = new string("k12_0x72be5d74");
	k[13] = new string("k13_0x80deb1fe");
	k[14] = new string("k14_0x9bdc06a7");
	k[15] = new string("k15_0xc19bf174");
	k[16] = new string("k16_0xe49b69c1");
	k[17] = new string("k17_0xefbe4786");
	k[18] = new string("k18_0x0fc19dc6");
	k[19] = new string("k19_0x240ca1cc");
	k[20] = new string("k20_0x2de92c6f");
	k[21] = new string("k21_0x4a7484aa");
	k[22] = new string("k22_0x5cb0a9dc");
	k[23] = new string("k23_0x76f988da");
	k[24] = new string("k24_0x983e5152");
	k[25] = new string("k25_0xa831c66d");
	k[26] = new string("k26_0xb00327c8");
	k[27] = new string("k27_0xbf597fc7");
	k[28] = new string("k28_0xc6e00bf3");
	k[29] = new string("k29_0xd5a79147");
	k[30] = new string("k30_0x06ca6351");
	k[31] = new string("k31_0x14292967");
	k[32] = new string("k32_0x27b70a85");
	k[33] = new string("k33_0x2e1b2138");
	k[34] = new string("k34_0x4d2c6dfc");
	k[35] = new string("k35_0x53380d13");
	k[36] = new string("k36_0x650a7354");
	k[37] = new string("k37_0x766a0abb");
	k[38] = new string("k38_0x81c2c92e");
	k[39] = new string("k39_0x92722c85");
	k[40] = new string("k40_0xa2bfe8a1");
	k[41] = new string("k41_0xa81a664b");
	k[42] = new string("k42_0xc24b8b70");
	k[43] = new string("k43_0xc76c51a3");
	k[44] = new string("k44_0xd192e819");
	k[45] = new string("k45_0xd6990624");
	k[46] = new string("k46_0xf40e3585");
	k[47] = new string("k47_0x106aa070");
	k[48] = new string("k48_0x19a4c116");
	k[49] = new string("k49_0x1e376c08");
	k[50] = new string("k50_0x2748774c");
	k[51] = new string("k51_0x34b0bcb5");
	k[52] = new string("k52_0x391c0cb3");
	k[53] = new string("k53_0x4ed8aa4a");
	k[54] = new string("k54_0x5b9cca4f");
	k[55] = new string("k55_0x682e6ff3");
	k[56] = new string("k56_0x748f82ee");
	k[57] = new string("k57_0x78a5636f");
	k[58] = new string("k58_0x84c87814");
	k[59] = new string("k59_0x8cc70208");
	k[60] = new string("k60_0x90befffa");
	k[61] = new string("k61_0xa4506ceb");
	k[62] = new string("k62_0xbef9a3f7");
	k[63] = new string("k63_0xc67178f2");

	for (int i = 0; i < 64; i++) {
		sprintf(buf, "%02d", i);

		in[i] = new string("in");
		in[i]->append(buf);
	}


	/* PROCEDURE */

	// extension
	{
		string* s0 = new string();
		string* s1 = new string();

		for (int i = 0; i < 16; i++) {
			w[i] = in[i];
		}

		for (int i = 16; i < 64; i++) {
			// s0 := (w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
			//sprintf(buf, "((%s) RR 7) xor ((%s) RR 18) xor ((%s) RS 3)", w[i-15]->c_str(), w[i-15]->c_str(), w[i-15]->c_str());
			sprintf(buf, "(w[%02d] RR 7) xor (w[%02d] RR 18) xor (w[%02d] RS 3)", i-15, i-15, i-15);
			s0 = new string(buf);

			// s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
			//sprintf(buf, "((%s) RR 17) xor ((%s) RR 19) xor ((%s) RS 10)", w[i-2]->c_str(), w[i-2]->c_str(), w[i-2]->c_str());
			sprintf(buf, "(w[%02d] RR 17) xor (w[%02d] RR 19) xor (w[%02d] RS 10)", i-2, i-2, i-2);
			s1 = new string(buf);

			// w[i] := w[i-16] + s0 + w[i-7] + s1
			sprintf(buf, "w[%02d] + (%s) + w[%02d] + (%s)", i-16, s0->c_str(), i-7, s1->c_str());
			w[i] = new string(buf);

#if 0
			cout << "w[" << i << "] = " << *w[i] << endl;
#endif
		}
	}

	// compression
	{
		a = new string(*hx[0]);
		b = new string(*hx[1]);
		c = new string(*hx[2]);
		d = new string(*hx[3]);
		e = new string(*hx[4]);
		f = new string(*hx[5]);
		g = new string(*hx[6]);
		h = new string(*hx[7]);

		for (int i = 0; i < 64; i++) {
			string* an;
			string* bn;
			string* cn;
			string* dn;
			string* en;
			string* fn;
			string* gn;
			string* hn;

	        hn = g;
	        gn = f;
	        fn = e;
	        sprintf(buf, "(%s + temp1.%02d)", d->c_str(), i);
	        //sprintf(buf, "(%s + temp1.%02d=f((%s), (%s), (%s), (%s)))", d->c_str(), i, e->c_str(), f->c_str(), g->c_str(), h->c_str());
	        en = new string(buf);
	        dn = c;
	        cn = b;
	        bn = a;
	        sprintf(buf, "(temp1.%02d) + temp2.%02d)", i, i);
	        //sprintf(buf, "(temp1.%02d=f((%s), (%s), (%s), (%s)) + temp2.%02d=f((%s), (%s), (%s)))", i, e->c_str(), f->c_str(), g->c_str(), h->c_str(), i, a->c_str(), b->c_str(), c->c_str());
	        an = new string(buf);

	        a = an;
	        b = bn;
	        c = cn;
	        d = dn;
	        e = en;
	        f = fn;
	        g = gn;
	        h = hn;

#if 1
	        cout << "Iter " << i << ": " << endl;
	        cout << "  a = " << *a << endl;
	        cout << "  b = " << *b << endl;
	        cout << "  c = " << *c << endl;
	        cout << "  d = " << *d << endl;
	        cout << "  e = " << *e << endl;
	        cout << "  f = " << *f << endl;
	        cout << "  g = " << *g << endl;
	        cout << "  h = " << *h << "\r\n";
#endif
		}
	}

	free(buf);
	return 0;
}


/*
Note 1: All variables are 32 bit unsigned integers and addition is calculated modulo 232
Note 2: For each round, there is one round constant k[i] and one entry in the message schedule array w[i], 0 ≤ i ≤ 63
Note 3: The compression function uses 8 working variables, a through h
Note 4: Big-endian convention is used when expressing the constants in this pseudocode,
    and when parsing message block data from bytes to words, for example,
    the first word of the input message "abc" after padding is 0x61626380

Initialize hash values:
(first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19):
h0 := 0x6a09e667
h1 := 0xbb67ae85
h2 := 0x3c6ef372
h3 := 0xa54ff53a
h4 := 0x510e527f
h5 := 0x9b05688c
h6 := 0x1f83d9ab
h7 := 0x5be0cd19

Initialize array of round constants:
(first 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311):
k[0..63] :=
   0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
   0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
   0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
   0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
   0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
   0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
   0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

Pre-processing:
append the bit '1' to the message
append k bits '0', where k is the minimum number >= 0 such that the resulting message
    length (modulo 512 in bits) is 448.
append length of message (without the '1' bit or padding), in bits, as 64-bit big-endian integer
    (this will make the entire post-processed length a multiple of 512 bits)

Process the message in successive 512-bit chunks:
break message into 512-bit chunks
for each chunk
    create a 64-entry message schedule array w[0..63] of 32-bit words
    (The initial values in w[0..63] don't matter, so many implementations zero them here)
    copy chunk into first 16 words w[0..15] of the message schedule array

    Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
    for i from 16 to 63
        s0 := (w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
        s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
        w[i] := w[i-16] + s0 + w[i-7] + s1

    Initialize working variables to current hash value:
    a := h0
    b := h1
    c := h2
    d := h3
    e := h4
    f := h5
    g := h6
    h := h7

    Compression function main loop:
    for i from 0 to 63
        S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
        ch := (e and f) xor ((not e) and g)
        temp1 := h + S1 + ch + k[i] + w[i]
        S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
        maj := (a and b) xor (a and c) xor (b and c)
        temp2 := S0 + maj

        h := g
        g := f
        f := e
        e := d + temp1
        d := c
        c := b
        b := a
        a := temp1 + temp2

    Add the compressed chunk to the current hash value:
    h0 := h0 + a
    h1 := h1 + b
    h2 := h2 + c
    h3 := h3 + d
    h4 := h4 + e
    h5 := h5 + f
    h6 := h6 + g
    h7 := h7 + h

Produce the final hash value (big-endian):
digest := hash := h0 append h1 append h2 append h3 append h4 append h5 append h6 append h7
*/
