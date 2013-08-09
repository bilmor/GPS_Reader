// GPS XML reader //<>//
//   reads a .gpx XML file output from LoadMyTracks (http://www.loadmytracks.com/)
// testing addition

import processing.pdf.*;

String[] inputData;   // holds the whole data file
String[] dataLine;    // each line after split()
//TrackPoint[] theTracklog = new TrackPoint[30]; // big enough to handle several 
int logLength = 0;                                 // concatenated gps files

float minLongitude = 999, maxLongitude = -999;
float minLatitude = 999, maxLatitude = -999;
//float minElevation = 9999, maxElevation = 0;
//int minDatestamp = 9999, maxDatestamp = 0;
//int minTimestamp = 9999, maxTimestamp = 0;

String inputFilename = "FLAG";
float lastX = 0;
float lastY = 0;
Boolean segFlag = false;

float screenAspect, geoAspect;
float sideMargin, topMargin;

XML gpxFile;

PrintWriter datafile;
ArrayList<TrackPoint> trackLog;

void setup() {
  size(900, 1200);
  background(255);
  frameRate(1000);
  //  beginRecord(PDF, "Test7.pdf");
  colorMode(HSB, 1.0, 100, 100);

  selectInput("Select a file to draw:", "fileSelected");

  while (inputFilename == "FLAG")  //  wait for file selection
    delay(200);

  if (inputFilename != "")  // if user didn't cancel
  {
    trackLog = new ArrayList<TrackPoint>(10000);

    // read in previous data
    File datafiletest = new File (dataPath("datafile"));
    if (datafiletest.exists())
    {
      inputData = loadStrings("datafileout.txt"); //<>//
      if (inputData != null)
      {
        for (int i=0; i<inputData.length; i++)  //  for each line in inputData
        {
          dataLine = split(inputData[i], "\t");
          trackLog.add(new TrackPoint(dataLine[0], float(dataLine[1]), 
          float(dataLine[2]), float(dataLine[3]), 
          boolean(dataLine[4])));
        }
      }
    }
    else println ("no datafile");
    

    // Load XML file
    gpxFile = loadXML(inputFilename);

    // Get all the child nodes named "trkseg"
    XML[] segments = gpxFile.getChildren("trk/trkseg");

    // for each segment
    for (int i=0; i<segments.length; i++)
    {
      segFlag = true;

      // get its trackpoints
      XML[] trackpoints = segments[i].getChildren("trkpt");

      // for each trackpoint
      for (int j=0; j<trackpoints.length; j++)
      {
        // get attributes
        float latitude  = trackpoints[j].getFloat("lat");
        float longitude = trackpoints[j].getFloat("lon");

        // get elements
        XML timeElement = trackpoints[j].getChild("time");
        String time = timeElement.getContent();

        XML elevationElement = trackpoints[j].getChild("ele");
        float elevation = elevationElement.getFloatContent();

        for (int k=0; k<=logLength; k++) //<>//
        {
          TrackPoint theTrackPoint = trackLog.get(k);

          if (time.compareTo(theTrackPoint.datetime) >= 0 ||
            (//logLength > 0 &&
            latitude  == theTrackPoint.latitude &&
            longitude == theTrackPoint.longitude))
          {
            continue;
          }
          else
          {
            // build a new entry
            trackLog.add(k, new TrackPoint(time, latitude, longitude, elevation, segFlag));
            segFlag = false;
            logLength++;
            break;
          }
        }  // for k
      }  // for j
    }  // for i

    // write out the data file
    datafile = createWriter("data/datafileout.txt");
    for (int i=0; i<trackLog.size(); i++)
    {
      TrackPoint temp = trackLog.get(i);
      datafile.println(temp.datetime + "\t" + temp.latitude + "\t" + temp.longitude + 
                       "\t" + temp.elevation + "\t" + temp.segment);
    }
    datafile.flush();
    datafile.close();

      //  calculate maxima and minima
    for (int j=0; j<logLength; j++)
    {
      TrackPoint temp = trackLog.get(j);
      if (temp.latitude  > maxLatitude)  maxLatitude  = temp.latitude;
      if (temp.latitude  < minLatitude)  minLatitude  = temp.latitude;
      if (temp.longitude > maxLongitude) maxLongitude = temp.longitude;
      if (temp.longitude < minLongitude) minLongitude = temp.longitude;

      //      if (theTracklog[j].datestamp > maxDatestamp) maxDatestamp = theTracklog[j].datestamp;
      //      if (theTracklog[j].datestamp < minDatestamp) minDatestamp = theTracklog[j].datestamp;
      //      if (theTracklog[j].timestamp > maxTimestamp) maxTimestamp = theTracklog[j].timestamp;
      //      if (theTracklog[j].timestamp < minTimestamp) minTimestamp = theTracklog[j].timestamp;

      //      if (theTracklog[j].elevation > maxElevation) maxElevation = theTracklog[j].elevation;
      //      if (theTracklog[j].elevation < minElevation) minElevation = theTracklog[j].elevation;
    }

    // calculate screen and geo aspect ratios
    float latFactor = cos(radians((minLatitude+maxLatitude)/2));
    screenAspect = float(width)/height;
    geoAspect = (latFactor*(maxLongitude-minLongitude))/(maxLatitude-minLatitude);

    // and set margins accordingly
    if (screenAspect > geoAspect)
    {
      sideMargin = (width-(geoAspect/screenAspect)*width)/2;
      topMargin = 10;
    }
    else
    {
      sideMargin = 10;
      topMargin = (height-(screenAspect/geoAspect)*height)/2;
    }

    //  set up first point
    TrackPoint temp = trackLog.get(0);
    lastX = map(temp.longitude, minLongitude, maxLongitude, sideMargin, width-sideMargin);
    lastY = height-map(temp.latitude, minLatitude, maxLatitude, topMargin, height-topMargin);

    //  debugging curiousae
    //    println(logLength);
    //    println();
    //    println(minLatitude  + "\t" + maxLatitude  + "\t" + (maxLatitude-minLatitude));
    //    println(minLongitude + "\t" + maxLongitude + "\t" + (maxLongitude-minLongitude));
    //    println(minElevation + " " + maxElevation);
    //    println();
    //    println(screenAspect + " " + geoAspect);
    //    println();
    //    println(minDatestamp + " " + maxDatestamp);
    //    println(minTimestamp + " " + maxTimestamp);
    // 
    //    println("----");
  }
  else exit();  // inputFilename == "", user cancelled
}

int logIndex = 1;      // start with second TrackPoint 'cause the first was set in setup()

void draw()
{
  if ( logIndex<logLength)
  {
    TrackPoint temp = trackLog.get(logIndex);

    // map longitude and latitude into screen coordinates
    float x = map(temp.longitude, minLongitude, maxLongitude, sideMargin, width-sideMargin);
    float y = height-map(temp.latitude, minLatitude, maxLatitude, topMargin, height-topMargin);

    //    float hue = map(temp.elevation, minElevation, maxElevation, 0, .75);
    float hue = (float(logIndex)/logLength)*.75;  // logIndex standing in for time
    stroke(hue, 100, 100);

    if (temp.segment)  // we have a new segment
    {
      lastX = x;       // so suppress the first point
      lastY = y;
    }

    //    point (x, y);
    line(lastX, lastY, x, y);  // draw the line
    lastX = x; 
    lastY = y;
    logIndex++;
  } 
  else
  {
    delay(100);  // we're done, wait for keypress
  }
}

// callback routine from selectInput
void fileSelected(File selection) {
  if (selection == null) {                        //  user cancelled
    inputFilename = "";
  } 
  else {
    inputFilename = selection.getAbsolutePath();  // we have a filename
  }
}

void keyPressed()
{
  endRecord();
  exit();
}
