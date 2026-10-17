/**
 * Tracklet Mapbox Web Adapter
 * Provides an encapsulated bridge between Flutter Web and Mapbox GL JS v3.
 */
(function () {
  'use strict';

  var instances = {};

  function isSupported() {
    return typeof mapboxgl !== 'undefined' && typeof mapboxgl.supported === 'function' && mapboxgl.supported();
  }

  function createMarkerElement(bus, isSelected, onClick) {
    var el = document.createElement('div');
    el.className = 'tracklet-bus-marker' + (isSelected ? ' tracklet-bus-selected' : '');
    el.setAttribute('role', 'button');
    el.setAttribute('tabindex', '0');
    el.setAttribute('aria-label', (bus.name || 'Bus') + ', ' + (bus.status || 'active') + ' bus');

    var routeColor = bus.routeColor || '#6F61EF';
    var isStale = bus.isStale === true;
    var isStationary = bus.isStationary === true;
    var borderColor = isSelected ? '#1A1D20' : (isStale ? '#8C95A0' : (isStationary ? '#D97706' : routeColor));
    var bgColor = isStale ? '#F1F3F5' : '#FFFFFF';

    el.style.width = isSelected ? '46px' : '40px';
    el.style.height = isSelected ? '46px' : '40px';
    el.style.borderRadius = '50%';
    el.style.backgroundColor = bgColor;
    el.style.border = (isSelected ? '3px' : '2.5px') + ' solid ' + borderColor;
    el.style.boxShadow = isSelected ? '0 0 0 4px rgba(111, 97, 239, 0.35), 0 4px 12px rgba(0,0,0,0.2)' : '0 2px 6px rgba(0,0,0,0.18)';
    el.style.display = 'flex';
    el.style.alignItems = 'center';
    el.style.justifyContent = 'center';
    el.style.cursor = 'pointer';
    el.style.transition = 'transform 0.2s cubic-bezier(0.2, 0, 0, 1), box-shadow 0.2s ease';
    el.style.outline = 'none';

    // Inner icon container
    var icon = document.createElement('div');
    icon.innerHTML = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="' + borderColor + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 6v6"/><path d="M15 6v6"/><path d="M2 12h19.6"/><path d="M18 18h3s.5-1.7.8-2.8c.1-.4.2-.8.2-1.2 0-.4-.1-.8-.2-1.2l-1.4-5C20.1 6.6 19 6 18 6H4c-1 0-2.1.6-2.4 1.8l-1.4 5c-.1.4-.2.8-.2 1.2 0 .4.1.8.2 1.2.3 1.1.8 2.8.8 2.8h3"/><circle cx="7" cy="18" r="2"/><path d="M9 18h5"/><circle cx="16" cy="18" r="2"/></svg>';
    el.appendChild(icon);

    function handleClick(e) {
      e.stopPropagation();
      if (typeof onClick === 'function') {
        onClick(bus.id);
      }
    }

    el.addEventListener('click', handleClick);
    el.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        handleClick(e);
      }
    });

    return el;
  }

  window.TrackletMapbox = {
    isSupported: isSupported,

    initMap: function (viewId, container, config, callbacks) {
      if (typeof config === 'string') {
        try { config = JSON.parse(config); } catch (e) { config = {}; }
      }
      if (!isSupported()) {
        if (callbacks && typeof callbacks.onError === 'function') {
          callbacks.onError('WebGL is not supported in this browser.');
        }
        return false;
      }

      if (!config || !config.accessToken) {
        if (callbacks && typeof callbacks.onError === 'function') {
          callbacks.onError('Mapbox public access token is required.');
        }
        return false;
      }

      try {
        mapboxgl.accessToken = config.accessToken;

        var center = [
          (config.centerLng !== undefined) ? config.centerLng : 75.9337,
          (config.centerLat !== undefined) ? config.centerLat : 11.3216
        ];

        var map = new mapboxgl.Map({
          container: container,
          style: config.styleUrl || 'mapbox://styles/mapbox/streets-v12',
          center: center,
          zoom: (config.zoom !== undefined) ? config.zoom : 16.5,
          minZoom: (config.minZoom !== undefined) ? config.minZoom : 14.0,
          maxZoom: (config.maxZoom !== undefined) ? config.maxZoom : 19.5,
          attributionControl: true
        });

        // Add standard navigation controls (zoom, compass)
        map.addControl(new mapboxgl.NavigationControl({ showCompass: true, showZoom: true }), 'top-right');

        var instance = {
          map: map,
          busMarkers: {},
          callbacks: callbacks || {},
          selectedBusId: null,
          userMarker: null
        };

        map.on('load', function () {
          // Initialize routes GeoJSON source and layers
          map.addSource('tracklet-routes', {
            type: 'geojson',
            data: { type: 'FeatureCollection', features: [] }
          });

          map.addLayer({
            id: 'tracklet-routes-line',
            type: 'line',
            source: 'tracklet-routes',
            layout: { 'line-join': 'round', 'line-cap': 'round' },
            paint: {
              'line-color': ['get', 'color'],
              'line-width': ['case', ['get', 'isSelected'], 5.5, 3.5],
              'line-opacity': ['case', ['get', 'isSelected'], 0.95, 0.45]
            }
          });

          // Initialize stops GeoJSON source and layer
          map.addSource('tracklet-stops', {
            type: 'geojson',
            data: { type: 'FeatureCollection', features: [] }
          });

          map.addLayer({
            id: 'tracklet-stops-circle',
            type: 'circle',
            source: 'tracklet-stops',
            paint: {
              'circle-radius': ['case', ['get', 'isMajorHub'], 7, 5],
              'circle-color': '#FFFFFF',
              'circle-stroke-color': ['get', 'color'],
              'circle-stroke-width': ['case', ['get', 'isSelected'], 3.5, 2.5]
            }
          });

          map.on('click', 'tracklet-stops-circle', function (e) {
            if (e.features && e.features.length > 0) {
              e.originalEvent.stopPropagation();
              var stopId = e.features[0].properties.id;
              if (instance.callbacks && typeof instance.callbacks.onStopClick === 'function') {
                instance.callbacks.onStopClick(stopId);
              }
            }
          });

          map.on('mouseenter', 'tracklet-stops-circle', function () {
            map.getCanvas().style.cursor = 'pointer';
          });
          map.on('mouseleave', 'tracklet-stops-circle', function () {
            map.getCanvas().style.cursor = '';
          });

          if (instance.callbacks && typeof instance.callbacks.onLoad === 'function') {
            instance.callbacks.onLoad();
          }
        });

        map.on('dragstart', function () {
          if (instance.callbacks && typeof instance.callbacks.onUserGesture === 'function') {
            instance.callbacks.onUserGesture();
          }
        });

        map.on('moveend', function () {
          var c = map.getCenter();
          if (instance.callbacks && typeof instance.callbacks.onCameraChange === 'function') {
            instance.callbacks.onCameraChange(c.lat, c.lng, map.getZoom());
          }
        });

        map.on('click', function (e) {
          if (instance.callbacks && typeof instance.callbacks.onMapClick === 'function') {
            instance.callbacks.onMapClick(e.lngLat.lat, e.lngLat.lng);
          }
        });

        instances[viewId] = instance;
        return true;
      } catch (err) {
        console.error('TrackletMapbox init error:', err);
        if (callbacks && typeof callbacks.onError === 'function') {
          callbacks.onError(err.message || String(err));
        }
        return false;
      }
    },

    updateBuses: function (viewId, buses, selectedBusId) {
      if (typeof buses === 'string') {
        try { buses = JSON.parse(buses); } catch (e) { buses = []; }
      }
      var instance = instances[viewId];
      if (!instance || !instance.map) return;

      instance.selectedBusId = selectedBusId;
      var activeIds = {};

      for (var i = 0; i < buses.length; i++) {
        var bus = buses[i];
        if (bus.lat === undefined || bus.lng === undefined) continue;
        activeIds[bus.id] = true;

        var isSelected = (bus.id === selectedBusId);
        var existing = instance.busMarkers[bus.id];

        if (existing) {
          existing.marker.setLngLat([bus.lng, bus.lat]);
          // Recreate element if selection state changed
          if (existing.isSelected !== isSelected || existing.isStale !== bus.isStale) {
            existing.marker.remove();
            var newEl = createMarkerElement(bus, isSelected, function (id) {
              if (instance.callbacks && typeof instance.callbacks.onBusClick === 'function') {
                instance.callbacks.onBusClick(id);
              }
            });
            var newMarker = new mapboxgl.Marker({ element: newEl, anchor: 'center' })
              .setLngLat([bus.lng, bus.lat])
              .addTo(instance.map);
            instance.busMarkers[bus.id] = {
              marker: newMarker,
              isSelected: isSelected,
              isStale: bus.isStale
            };
          }
        } else {
          var el = createMarkerElement(bus, isSelected, function (id) {
            if (instance.callbacks && typeof instance.callbacks.onBusClick === 'function') {
              instance.callbacks.onBusClick(id);
            }
          });
          var marker = new mapboxgl.Marker({ element: el, anchor: 'center' })
            .setLngLat([bus.lng, bus.lat])
            .addTo(instance.map);

          instance.busMarkers[bus.id] = {
            marker: marker,
            isSelected: isSelected,
            isStale: bus.isStale
          };
        }
      }

      // Remove markers no longer active
      for (var id in instance.busMarkers) {
        if (!activeIds[id]) {
          instance.busMarkers[id].marker.remove();
          delete instance.busMarkers[id];
        }
      }
    },

    updateRoutes: function (viewId, routes, selectedRouteId) {
      if (typeof routes === 'string') {
        try { routes = JSON.parse(routes); } catch (e) { routes = []; }
      }
      var instance = instances[viewId];
      if (!instance || !instance.map) return;

      var map = instance.map;
      var source = map.getSource('tracklet-routes');
      if (!source) return;

      var features = [];
      for (var i = 0; i < routes.length; i++) {
        var r = routes[i];
        if (!r.points || r.points.length < 2) continue;
        var coords = [];
        for (var j = 0; j < r.points.length; j++) {
          coords.push([r.points[j].lng, r.points[j].lat]);
        }
        features.push({
          type: 'Feature',
          properties: {
            id: r.id,
            color: r.color || '#6F61EF',
            isSelected: (r.id === selectedRouteId)
          },
          geometry: {
            type: 'LineString',
            coordinates: coords
          }
        });
      }

      source.setData({
        type: 'FeatureCollection',
        features: features
      });
    },

    updateStops: function (viewId, stops, selectedStopId) {
      if (typeof stops === 'string') {
        try { stops = JSON.parse(stops); } catch (e) { stops = []; }
      }
      var instance = instances[viewId];
      if (!instance || !instance.map) return;

      var map = instance.map;
      var source = map.getSource('tracklet-stops');
      if (!source) return;

      var features = [];
      for (var i = 0; i < stops.length; i++) {
        var s = stops[i];
        features.push({
          type: 'Feature',
          properties: {
            id: s.id,
            name: s.name,
            color: s.color || '#6F61EF',
            isMajorHub: s.isMajorHub === true,
            isSelected: (s.id === selectedStopId)
          },
          geometry: {
            type: 'Point',
            coordinates: [s.lng, s.lat]
          }
        });
      }

      source.setData({
        type: 'FeatureCollection',
        features: features
      });
    },

    updateUserLocation: function (viewId, loc) {
      if (typeof loc === 'string') {
        try { loc = JSON.parse(loc); } catch (e) { loc = null; }
      }
      var instance = instances[viewId];
      if (!instance || !instance.map) return;

      if (!loc || loc.lat === undefined || loc.lng === undefined) {
        if (instance.userMarker) {
          instance.userMarker.remove();
          instance.userMarker = null;
        }
        return;
      }

      if (instance.userMarker) {
        instance.userMarker.setLngLat([loc.lng, loc.lat]);
      } else {
        var el = document.createElement('div');
        el.className = 'tracklet-user-location-marker';
        el.style.width = '20px';
        el.style.height = '20px';
        el.style.borderRadius = '50%';
        el.style.backgroundColor = '#3B82F6';
        el.style.border = '3px solid #FFFFFF';
        el.style.boxShadow = '0 0 0 3px rgba(59, 130, 246, 0.4), 0 2px 4px rgba(0,0,0,0.2)';
        instance.userMarker = new mapboxgl.Marker({ element: el, anchor: 'center' })
          .setLngLat([loc.lng, loc.lat])
          .addTo(instance.map);
      }
    },

    flyTo: function (viewId, lng, lat, zoom) {
      var instance = instances[viewId];
      if (!instance || !instance.map) return;
      instance.map.flyTo({
        center: [lng, lat],
        zoom: zoom !== undefined ? zoom : instance.map.getZoom(),
        essential: true,
        duration: 450
      });
    },

    fitBounds: function (viewId, boundsArray, padding) {
      var instance = instances[viewId];
      if (!instance || !instance.map || !boundsArray || boundsArray.length !== 4) return;
      var bounds = [
        [boundsArray[0], boundsArray[1]], // [minLng, minLat]
        [boundsArray[2], boundsArray[3]]  // [maxLng, maxLat]
      ];
      var pad = padding || { top: 60, bottom: 60, left: 60, right: 60 };
      instance.map.fitBounds(bounds, {
        padding: pad,
        maxZoom: 17.5,
        duration: 500
      });
    },

    destroy: function (viewId) {
      var instance = instances[viewId];
      if (!instance) return;
      if (instance.userMarker) {
        instance.userMarker.remove();
      }
      for (var id in instance.busMarkers) {
        instance.busMarkers[id].marker.remove();
      }
      if (instance.map) {
        instance.map.remove();
      }
      delete instances[viewId];
    }
  };
})();
