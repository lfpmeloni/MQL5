//+------------------------------------------------------------------+
//|                                               HiLo Activator.mq5 |
//|                                                             lfpm |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "lfpm"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//Link para indicador pronto
//https://www.mql5.com/pt/code/viewcode/1496/143551/gann_hi_lo_activator_ssl.mq5

#property indicator_chart_window
#property indicator_buffers   5
#property indicator_plots     1
//Output line
#property indicator_type1  DRAW_COLOR_LINE       //DRAW_COLOR_ZIGZAG
#property indicator_color1 clrDodgerBlue, clrOrangeRed
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_label1 "GibexHL (8,SMA)"       //"GHL (13,SMMA)
//Input parameters
input uint           input_period = 8;              //Period
input ENUM_MA_METHOD input_method_ma = MODE_SMA;   //Metodo da media movel
//Buffers
double gann_buffer[];
double color_buffer[];
double hi_buffer[];
double lo_buffer[];
double trend_buffer[];
//Variaveis globais
int hi_handle;
int lo_handle;
int period;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
   {
   //---Check period
   period=(int)fmax(input_period,2);
   //---Set buffer
   SetIndexBuffer(0,gann_buffer);
   SetIndexBuffer(1,color_buffer);
   SetIndexBuffer(2,hi_buffer);
   SetIndexBuffer(3,lo_buffer);
   SetIndexBuffer(4,trend_buffer);
   //---Set direction
   ArraySetAsSeries(gann_buffer,true);
   ArraySetAsSeries(color_buffer,true);  
   ArraySetAsSeries(hi_buffer,true);
   ArraySetAsSeries(lo_buffer,true);
   ArraySetAsSeries(trend_buffer,true);  
   //---Get handles
   hi_handle = iMA(NULL,0,period,0,input_method_ma,PRICE_HIGH);
   lo_handle = iMA(NULL,0,period,0,input_method_ma,PRICE_LOW);
   if(hi_handle==INVALID_HANDLE||lo_handle==INVALID_HANDLE){
      Print("Unable to create handle for iMA");
      return(INIT_FAILED);    
   }
   //---Set indicators properties
   string short_name = StringFormat("Gann High-Low Activator SSL (%u, %s)",period,StringSubstr(EnumToString(input_method_ma),5));
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   //---Set label
   short_name = StringFormat("GHL (%u, %s)",period,StringSubstr(EnumToString(input_method_ma),5));
   PlotIndexSetString(0,PLOT_LABEL,short_name);
   //---Done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total<period+1)return(0);
   ArraySetAsSeries(close,true);
   //---
   int limit;
   if(rates_total<prev_calculated || prev_calculated<=0){
      limit=rates_total-period-1;
      ArrayInitialize(gann_buffer,EMPTY_VALUE);
      ArrayInitialize(color_buffer,0);
      ArrayInitialize(hi_buffer,0);
      ArrayInitialize(lo_buffer,0);
      ArrayInitialize(trend_buffer,0);      
   }  else limit = rates_total-prev_calculated;
   //---Get MA
   if(CopyBuffer(hi_handle,0,0,limit+1,hi_buffer)!=limit+1)return(0);
   if(CopyBuffer(lo_handle,0,0,limit+1,lo_buffer)!=limit+1)return(0);
   //---Main cycle
   for(int i = limit; i>=0 && !_StopFlag; i--){
      trend_buffer[i]=trend_buffer[i+1];
      //---
      if(NormalizeDouble(close[i],_Digits)>NormalizeDouble(hi_buffer[i+1],_Digits)) trend_buffer[i]=1;
      if(NormalizeDouble(close[i],_Digits)<NormalizeDouble(lo_buffer[i+1],_Digits)) trend_buffer[i]=-1;
      //---
      if(trend_buffer[i]<0){
         gann_buffer[i]=hi_buffer[i];
         color_buffer[i]=1;
      }
      if(trend_buffer[i]>0){
         gann_buffer[i]=lo_buffer[i];
         color_buffer[i]=0;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
 
//+------------------------------------------------------------------+
//| Logica para HiLo Activator em MQL4                               |
//+------------------------------------------------------------------+

//   for(shift=i; shift>=0;shift--)
//     {
//      VALUE1=iMA(NULL,0,R,0,MODE_SMA,PRICE_HIGH,shift+1);
//      VALUE2=iMA(NULL,0,R,0,MODE_SMA,PRICE_LOW,shift+1);
//      //----
//      if(Close[shift+1]<VALUE2)Swing=-1;
//      if(Close[shift+1]>VALUE1)Swing=1;
//      if(Swing==1) { HighBuffer[shift]=VALUE2; LowBuffer[shift]=0;  }
//      if(Swing==-1) { LowBuffer[shift]=VALUE1; HighBuffer[shift]=0; }
//      //----
//     }
//   return(0);