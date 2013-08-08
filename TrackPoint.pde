class TrackPoint
{
  String datetime;
  float latitude;
  float longitude;
  float elevation;
  Boolean segment;


  TrackPoint(String dt, float lat, float lon, float ele, Boolean seg)
  {
    datetime = dt;
    latitude = lat;
    longitude = lon;
    elevation = ele;
    segment = seg;
  }
  
  TrackPoint()
  {
  }
}
