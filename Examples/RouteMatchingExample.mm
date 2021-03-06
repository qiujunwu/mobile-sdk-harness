//
//  RouteMatchingExample.cpp
//  ExampleApp
//
//  Created by Scott on 16/01/2014.
//  Copyright (c) 2014 eeGeo. All rights reserved.
//

#include "RouteMatchingExample.h"
#include "RouteBuilder.h"
#include "VectorMath.h"
#include "RouteStyle.h"

using namespace Examples;
using namespace Eegeo;
using namespace Eegeo::Routes;

RouteMatchingExample::RouteMatchingExample(RouteService& routeService,
                                           EegeoWorld& world,
                                           UIView* pView)
:m_routeService(routeService)
,m_world(world)
,m_pView(pView)
,m_createdRoutes(false)
,m_routesMatchedToNavigationGraph(false)
{
    
}

void RouteMatchingExample::CreateRoutes(bool shouldMatchToNavigationGraph)
{
    // This function generates some routes, potentially matching them to the navigation graph based on the
    // value of the shouldMatchToNavigationGraph parameter. The API used here to build and submit the routes
    // is not explained as has been covered in RouteDrawingExample.cpp - please refer to this example for more
    // information about these API points at http://sdk.eegeo.com/developers/mobiledocs/routes
    
    const float halfWidth = 5.f;
    const float routeSpeedMetersPerSecond = 40.f;
    const Eegeo::v4 routeRed(1, 0, 0, 0.6f);
    const Eegeo::v4 routeGreen(0, 1, 0, 0.6f);
    const Eegeo::v4 routeBlue(0, 0, 1, 0.6f);
    const float altitudeMeters = 3.f;
    Eegeo::Routes::Style::RouteStyle hardJoinStyle(Eegeo::Routes::Style::RouteStyle::JoinStyleHard, m_routeThicknessPolicy);
    Eegeo::Routes::Style::RouteStyle arcJoinStyle(Eegeo::Routes::Style::RouteStyle::JoinStyleArc, m_routeThicknessPolicy);
    
    RouteBuilder builder;
    
    // Create a route on roads at the north coast of San Francisco at Fishermans wharf. This route
    // demonstrates fitting to the road graph
    //
    std::vector<RouteVertex> fishermansWharfPoints = builder.Start(routeRed, halfWidth, routeSpeedMetersPerSecond, Routes::Road)
    .AddPoint(37.807173,-122.408929, altitudeMeters)
    .AddPoint(37.806982,-122.410527, altitudeMeters)
    .ChangeColor(routeGreen)
    .AddPoint(37.806059,-122.41035, altitudeMeters)
    .AddPoint(37.805847,-122.411986, altitudeMeters)
    .ChangeColor(routeRed)
    .AddPoint(37.805385,-122.411916, altitudeMeters)
    .AddPoint(37.805177,-122.413537, altitudeMeters)
    .ChangeColor(routeBlue)
    .AddPoint(37.805635,-122.413633, altitudeMeters)
    .AddPoint(37.80658,-122.413816, altitudeMeters)
    .FinishRoute();
    
    Route* route = m_routeService.CreateRoute(fishermansWharfPoints, hardJoinStyle, shouldMatchToNavigationGraph);
    m_routes.push_back(route);
    
    // Create a route at Buena Vista park in San Francisco - the park is on a hill, this example demonstrates
    // fitting to the road graph on elevated terrain.
    //
    std::vector<RouteVertex> buenaVistaPoints = builder.Start(routeBlue, halfWidth/2.f, routeSpeedMetersPerSecond, Routes::Road)
    .AddPoint(37.766088,-122.442888,altitudeMeters)
    .AddPoint(37.76597,-122.442698,altitudeMeters)
    .AddPoint(37.766037,-122.442576,altitudeMeters)
    .AddPoint(37.766129,-122.442381,altitudeMeters)
    .AddPoint(37.766171,-122.442263,altitudeMeters)
    .AddPoint(37.766307,-122.442053,altitudeMeters)
    .AddPoint(37.766667,-122.44175,altitudeMeters)
    .AddPoint(37.766945,-122.441635,altitudeMeters)
    .AddPoint(37.767274,-122.441549,altitudeMeters)
    .AddPoint(37.767683,-122.441276,altitudeMeters)
    .FinishRoute();
    
    m_routes.push_back(m_routeService.CreateRoute(buenaVistaPoints, arcJoinStyle, shouldMatchToNavigationGraph));
    
    // Create a route on Treasure Island in San Francisco. This route starts on the road network, but includes a
    // pedestrian section. The road vertices are colored red and the pedestrian section is colored blue. The
    // pedestrian section is not matched to any navigation graphs, while the road section is (if the value of
    // shouldMatchToNavigationGraph is true).
    //
    std::vector<RouteVertex> islandPoints = builder.Start(routeRed, halfWidth, routeSpeedMetersPerSecond, Routes::Road)
    .AddPoint(37.817416,-122.3681912, altitudeMeters)
    .AddPoint(37.818747,-122.369023, altitudeMeters)
    .AddPoint(37.818243,-122.370348, altitudeMeters)
    .AddPoint(37.820277,-122.3717, altitudeMeters)
    .AddPoint(37.820768,-122.370456, altitudeMeters)
    .AddPoint(37.822794,-122.371775, altitudeMeters)
    .ChangeClassification(Routes::Pedestrian)
    .ChangeColor(routeBlue)
    .AddPoint(37.822887,-122.371207, altitudeMeters)
    .AddPoint(37.822396,-122.370273, altitudeMeters)
    .AddPoint(37.824709,-122.370316, altitudeMeters)
    .FinishRoute();
    
    m_routes.push_back(m_routeService.CreateRoute(islandPoints, arcJoinStyle, shouldMatchToNavigationGraph));
    
    //We have created the routes so don't need to do so again.
    m_createdRoutes = true;
}

void RouteMatchingExample::DestroyRoutes()
{
    //Destroy all of the routes...
    for(std::vector<Route*>::iterator i = m_routes.begin(); i != m_routes.end(); ++ i)
    {
        //Destroy the route - we do not need to delete the route pointer ourselves, the API will handle this
        //as well as cleaning up associated views, etc.
        m_routeService.DestroyRoute(*i);
    }
    
    m_routes.clear();
    m_createdRoutes = false;
}

void RouteMatchingExample::Update(float dt)
{
    //Defer creating the routes until the loading state is over.
    if(m_world.Initialising()) {
        return;
    }
    
    //Just create the routes once.
    if(!m_createdRoutes)
    {
        CreateRoutes(m_routesMatchedToNavigationGraph);
        CreateAndBindUI();
    }
}

void RouteMatchingExample::Suspend()
{
    DestroyRoutes();
}

void RouteMatchingExample::ToggleMatching()
{
    m_routesMatchedToNavigationGraph = !m_routesMatchedToNavigationGraph;
    DestroyRoutes();
    CreateRoutes(m_routesMatchedToNavigationGraph);
}

//Create some UI to let us toggle route matching
@interface IRouteMatchingExampleBinding : NSObject

-(void) setExampleInstance:(RouteMatchingExample*)pExample :(UIButton*)pToggleMatching;
-(void) toggleMatching;

@end

@implementation IRouteMatchingExampleBinding

RouteMatchingExample* m_pRouteMatchingExample;
UIButton* m_pToggleMatching;

-(void) setExampleInstance:(RouteMatchingExample*)pExample :(UIButton*)pToggleMatching
{
    m_pRouteMatchingExample = pExample;
    m_pToggleMatching = pToggleMatching;
}

-(void) toggleMatching
{
    m_pRouteMatchingExample->ToggleMatching();
}

@end

static IRouteMatchingExampleBinding *pExampleWrapper = nil;

void RouteMatchingExample::CreateAndBindUI()
{
    if (pExampleWrapper == nil)
    {
        pExampleWrapper = [[IRouteMatchingExampleBinding alloc] init];
    }
    
    // Grab the window frame and adjust it for orientation
    UIView *rootView = [[[UIApplication sharedApplication] keyWindow]
                        rootViewController].view;
    CGRect originalFrame = [[UIScreen mainScreen] bounds];
    CGRect adjustedFrame = [rootView convertRect:originalFrame fromView:nil];
    
    float screenHeight = adjustedFrame.size.height - 80.f;
    
    UIButton * toggleMatchingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    toggleMatchingButton.frame = CGRectMake(10, screenHeight, 200, 50);
    [toggleMatchingButton setTitle:@"Toggle Match!" forState:UIControlStateNormal];
    [toggleMatchingButton addTarget:pExampleWrapper action:@selector(toggleMatching) forControlEvents:UIControlEventTouchDown];
    [m_pView addSubview:toggleMatchingButton];
    
    [pExampleWrapper setExampleInstance:this :toggleMatchingButton];
}
