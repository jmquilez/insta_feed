#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <sstream>

using namespace std;

const int N = 20000;
const char delim = ':';
const string dataFile = "data/snapshot.json";
const string outFileForChart = "res/chart.txt";
const string keyString = "performance";
long double maxMs = 16000;

struct frame
{
    long long int index;
    long long int startTime;
    long double elapsed;
    long long int build;
    long long int raster;
    long long int vsyncOverhead;
};

void getData(string& fileName, string askingMessage) {
    cout << askingMessage;
    getline(cin, fileName);
}

bool extractLine(string &data, string fileName)
{
    ifstream f(fileName);
    if (f.is_open())
    {
        getline(f, data);
        f.close();
        return true;
    }
    else
    {
        cerr << "El fichero \"" << fileName << "\" no ha podido ser abierto." << endl;
        return false;
    }
}

bool prepareFile(string fileName, ofstream &f)
{
    f.open(fileName, ios::out);
    if (f.is_open())
    {
        return true;
    }
    else
    {
        cerr << "El fichero \"" << fileName << "\" no ha podido ser abierto." << endl;
        return false;
    }
}

string extractFrameData(string data)
{
    string substr = data.substr(data.find(keyString) + 11, data.length() - 1);
    string substr1 = substr.substr(substr.find(keyString), substr.length() - 1);
    string substr2 = substr1.substr(substr1.find('[') + 1, substr1.find(']'));
    return substr2;
}

void processData(string data, frame frameVect[N])
{
    unsigned i = 0;
    string s;
    istringstream ss(data);
    while (getline(ss, s, delim))
    {
        if (s.find(']') >= s.length())
        {
            
            ss >> frameVect[i].index;
            //cout << frameVect[i].index << endl;
            getline(ss, s, delim);
            ss >> frameVect[i].startTime;
            //cout << frameVect[i].startTime << endl;
            getline(ss, s, delim);
            ss >> frameVect[i].elapsed;
            //cout << frameVect[i].elapsed << endl;
            getline(ss, s, delim);
            ss >> frameVect[i].build;
            //cout << frameVect[i].build << endl;
            getline(ss, s, delim);
            ss >> frameVect[i].raster;
            //cout << frameVect[i].raster << endl;
            getline(ss, s, delim);
            ss >> frameVect[i].vsyncOverhead;
            //cout << frameVect[i].vsyncOverhead << endl;
            i++;
        }
    }
    //Section used to print mesas (and) index of each peak
    /*for (unsigned i = 9032; i < 9129; i++) {
        if (frameVect[i].raster >= 17000) {
            cout << "J-"; //<< frameVect[i].index << "-";
            
        } else {
            cout << "N-"; //<< frameVect[i].index << "-";
        }
    }*/
}

void writeDataToFile(frame frameVect[N], int n, ofstream &f, string param)
{
    for (unsigned i = 0; i < n; i++)
    {
        double color;
        if (frameVect[i].elapsed > maxMs) {
            color = 1;
        } else {
            color = frameVect[i].elapsed / maxMs;
        }
        f << left << setw(9) << frameVect[i].index << "" << setw(9) << frameVect[i].elapsed << "" << color << endl;
    }
}

//COUPLES (2 JANKED) FRAMES OBSERVATION RARITY? 3's? 4's? 5's?
//TODO: RELEASE VS PROFILE
//TODO: VERY SLOW SCROLLING JANK?
//TODO: REMOVE MORE WIDGETS?
//TODO: SUDDEN SCROLLING STOP?

void writeChart(string filePath) {
    string fpWhExt = filePath.substr(0, filePath.length() - 4);
    stringstream ss;
    //set xrange [1:4282]; set yrange [16000:30000]; set size ratio 4000;
    //4282
    //10000
    //set yrange [16000:100000]
    cout << filePath << endl;
    //ss << "gnuplot -e \"set terminal gif; set xrange [1:11400]; set yrange [16000:100000]; set style data lines; plot \'" << filePath << "'\" > " << fpWhExt << ".gif";
    //u 1:2:3 w l lc palette z
    //set terminal gif size 600,500; set lmargin at screen 80.0/600; set border back; set rmargin at screen 579.0/600; set lmargin 0.1; set rmargin 0.1;
    //set border back; --> plots on border line too (1 pixel)
    //set lmargin at screen 10.0/400 --> REQUIRED .0
    //set terminal gif size 500,500; set lmargin at screen 50.0/500; set rmargin at screen 450.0/500; set border back; --> PLOTTING AREA OF 400 PIXELS WIDTH, FOR HEIGHT DO SAME BUT WITH LOWER AND UPPER MARGINS
    //TODO: how to set a color for each pixel data, without transition, although this model helps us set relationship between consecutive frames, spikes??
    ss << "gnuplot -e \"set terminal gif; set terminal gif size 500,500; set lmargin at screen 50.0/500; set rmargin at screen 450.0/500; set border back; set size 1,1; set cbrange [0:1]; set border back; set palette defined ( 0 '#008EFF', 0.9 '#9E00FF', 0.95 '#FF0087', 1.0 '#FF0000'); set xrange [1:2000]; set yrange [1:80000]; set style data lines; plot \'" << filePath << "' using 1:2:3 w l lc palette z \" > " << fpWhExt << ".gif";
    string sInvoke = ss.str(); // saving as ss.str().c_str() yields following characters as result: Ð2'
    system(sInvoke.c_str());
}

//NOTE: RECORD WHICH APPS ARE OPEN AT THE MOMENT?
//MESSAGE: I/Choreographer(26555): Skipped 30 frames!  The application may be doing too much work on its main thread.
//NOTE: WE ARE ONLY CHECKING FOR RASTER JANK
//LOADED LIST SCROLLING UP DOES NOT LAG?
//TODO, NOTE: TRY TO CHECK FOR MESAS WITHOUT PREPARING VIDEO
//TRY SLOW/SOFT SCROLLING AND FAST/HARD SCROLLING
//STOP SCROLLING FOR A WHILE, THEN SCROLL AND CHECK FOR MESAS
//STUDY PLAY&SCROLL LAG
//CHECK FIRST FRAME RENDERING --> NOT BLACK IMAGE/BLACK IMAGE JANK? / AT BEGINNING
//TRY WITH LOW/HIGH BATTERY
//SCROLLING CASES THAT CAUSE MORE JANK
//OTHER COMPILATION OPTIONS, AFTER COMMAND
//JANK WHEN ROTATING PHONE / UPON RECEIVING NOTIFICATION
//EXITING FRAME?
//RESUMING FRAME?
//TODO: SCROLLING UP/DOWN DIFFERENCES --> REPEATEDLY / BOUNDARY SCROLLING?
//TODO: STUDY UI JANK
//TODO: STUDY MESAS' HEIGHT
//TODO: STUDY JANK UPON CHANGING SCREENS / EXITING AND RESUMING ACTIVITIES (1st, 2nd, ... scroll?) --> YIELDS MESA
//TODO: CHECK MESAS' ACTUAL VISUAL PERFORMANCE --> do they lag actually?
//TODO: SWIPING SCREENS YIELDS MESAS?
//ISOLATED JANK FRAMES, PROBABILITY OF COUPLES APPEARING (CONSECUTIVE)?
//DOES UI JANK ACTUALLY YIELD VISUAL LAG?
//TODO, NOTE: THRESHOLD FOR MESAS --> 2 OR 3 FRAMES?
//NEXT TRIAL: WITH / WITHOUT PREPARING (NOT RENDERING)
//NEXT-2 TRIAL: WITH / WITHOUT PREPARING & WITH / WITHOUT CIRCULARPROGRESSINDICATOR (ALWAYS STOPPED?) (NOT RENDERING)

int main()
{
    string data = "";
    ofstream f;
    frame frameVect[N];
    string fileSrc;
    string fileDest;
    string paramToPlot = "x";
    getData(fileSrc, "Introduzca el nombre del archivo origen (extensión .json): ");
    getData(fileDest, "Introduzca el nombre del archivo destino (extensión .txt): ");
    //getData(paramToPlot, "Introduzca el parámetro a representar: ");
    if (extractLine(data, fileSrc))
    {
        string perfString = extractFrameData(data);
        //cout << perfString/*.substr(0, 10000)*/ << endl;
        if (prepareFile(fileDest, f))
        {
            processData(perfString, frameVect);
            //4282
            writeDataToFile(frameVect, 1198 /*11400*/, f, paramToPlot);
            writeChart(fileDest);
        }
    }
    return 0;
}

//frame 1960 16.3 ms
//NOTE: NO MESAS WITHOUT PREPARING??
//TODO, NOTE: OPEN ANOTHER WINDOWS IN COMPUTER, SEE LAG AFTER RETURNING?
//TODO: TRY WITH / WITHOUT RENDERING TEXTURE
//TODO: AUTOMATIZE TRIALS
//UI JANK WITHOUT PREPARING, ETC...
//TEST JANK WITH ANOTHER TAB ACTIVE IN COMPUTER/PHONE?
//SCROLL DIAGONALLY TO AVOID SCREEN SWIPING
//SCROLL HOLDING FINGER?
//WITH/WITHOUT CLOSING BEFORE RUN
//TODO: DOES PHONE/COMPUTER BATTERY COUNT?
//TEST WITH / WITHOUT NOTIFICATIONS
//SLOWER SCROLLING LAGGIER??
//TODO: CHECK TIME OF TESTING INSTANTS??

//TODO: SCROLL WITH BOT??

//TODO: FIRST 5000 FRAMES' JANK MATCH WITH SECOND 5000??

//LEAVE STALL TIMES??

//lagged when clicking screen of computer after blackout (resuming computer's activity, not touched phone)

//TODO, NOTE, CHECKED: NOTIFICATIONS YIELD MESA/S --> WHATSAPP MESSAGES

//TODO, NOTE: DOES JANK DEPEND ON EACH RUN? CHECK 1-5000 AND 5001-10000 FRAMES' MEAN AND COMPARE THEM

//TODO: LET SCROLLING END COMPLETELY --> DOES THAT YIELD JANK?

//WATCHING VIDEO ON COMPUTER WHILE SCROLLING ON MOBILE IMPROVED PERFORMANCE / WITH FULLSCREEN VIDEO / AD STOPS??

//SOFT SCROLLING YIELDED BETTER RESULTS??

//PERFORMANCE VIEW DOES NOT DETECT ALL THE JANK????

//TRY WITH RENDER OVERLAY/JUST CHANGE TAB ONCE????

//BAD WIFI = BETTER PERFORMANCE? (NOT EVEN LOADING)

//HOLDING PHONE IN AIR JANKS??

//TRY OTHER TABS THAN VIDEO

//TRY SLIDING DOWN PHONE PANEL --> JANKS??

//WATCHING VIDEO - CHECK PERFORMANCE VIEW - BACK TO VIDEO --> JANKS?? 

//OPENING / CHANGING FRONT VIEW TO ANOTHER APP JANKS? (COMPUTER)

//UNLOOKED FRAMES IN PERFORMANCE VIEW NOT REGISTERING JANK?? / ADS JANKS??

//MAYUS ON?? COMPUTER / PHONE

//VIDEO RESOLUTION?? / VOLUM MOD??

//CHANGE SCREEN?? / PLAY / PAUSE

//TRY PLAYING GAME MEANWHILE

//WHAT ABOUT MISSING FRAMES IN GRAPHS? (APPEAR IN PERFORMANCE VIEW BUT NOT IN GRAPHS) --> SCALE PROBLEM? (HAVEN'T CORROBORATED / OBSERVED)