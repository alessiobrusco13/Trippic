//
//  TripView.swift
//  Trippic
//
//  Created by Alessio Garzia Marotta Brusco on 04/05/22.
//

import MapKit
import SwiftUI

struct TripView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataController: DataController
    
    @State private var showingTripPhoto = false
    @State private var showingPhotosGrid = false
    @State private var gridNavigationLink = false
    @State private var showingLocationPicker = false
    @StateObject private var viewModel: ViewModel
    
    @FocusState private var editingName: Bool
    @State private var editingTrip = false
    @State private var newID: String?
    
    init(trip: Trip) {
        _viewModel = StateObject(wrappedValue: ViewModel(trip: trip))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button {
                    withAnimation {
                        viewModel.showingFullscreenMap.toggle()
                    }
                } label: {
                    Map(coordinateRegion: $viewModel.miniMapRegion, annotationItems: viewModel.trip.locations) { location in
                        MapMarker(coordinate: location.locationCoordinates, tint: Color("AccentColor"))
                    }
                    .disabled(true)
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding([.horizontal, .top])
                }
                .accessibilityLabel("Map")
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        Button {
                            withAnimation {
                                viewModel.zoomInMiniMap()
                            }
                        } label: {
                            Label("Zoom in", systemImage: "plus.magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                        
                        Divider()
                            .frame(width: 15)
                        
                        Button {
                            withAnimation {
                                viewModel.zoomOutMiniMap()
                            }
                        } label: {
                            Label("Zoom out", systemImage: "minus.magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.title2)
                    .padding(7)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(25)
                }
                .disabled(editingTrip)
                
                VStack(spacing: 8) {
                    Button {
                        if !editingTrip {
                            withAnimation(.spring()) {
                                showingTripPhoto.toggle()
                            }
                        }
                    } label: {
                        PhotoView(asset: $viewModel.trip.photo, content: CircleImage.init)
                    }
                    .buttonStyle(.noPressEffect)
                    .frame(width: 150, height: 150)
                    .padding(.top, -130)
                    .overlay {
                        if editingTrip {
                            PhotoPickerLink(idSelection: $newID) {
                                Image(systemName: "photo.fill.on.rectangle.fill")
                                    .font(.largeTitle)
                                    .contentShape(Rectangle())
                            }
                            .padding()
                            .background()
                            .cornerRadius(10)
                            .transition(.scale)
                            .padding(.top, -70)
                        }
                    }
                    
                    VStack {
                        if !editingTrip {
                            Text(viewModel.trip.name)
                                .font(.largeTitle.weight(.semibold))
                        } else {
                            HStack {
                                TextField("Enter trip name", text: $viewModel.trip.name)
                                    .focused($editingName)
                                    .font(.largeTitle.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                    .onSubmit {
                                        editingName = false
                                    }
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Done") {
                                    withAnimation {
                                        editingTrip = false
                                    }
                                }
                                .font(.title3.weight(.bold))
                            }
                            .frame(maxWidth: 364)
                        }
                        
                        HStack(spacing: 5) {
                            if !editingTrip {
                                Text(viewModel.trip.startDate, format: .dateTime.day().month())
                            } else {
                                DatePicker(
                                    "Start date",
                                    selection: $viewModel.trip.startDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.heavy))
                            
                            if !editingTrip {
                                Text(viewModel.trip.endDate, format: .dateTime.day().month())
                            } else {
                                DatePicker(
                                    "End date",
                                    selection: $viewModel.trip.endDate,
                                    in: viewModel.trip.startDate...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                        }
                        .padding(editingTrip ? 8 : 0)
                        
                        NotesRowView(notes: $viewModel.trip.notes)
                    }
                }
                
                ForEach($viewModel.trip.locations) { $location in
                    LocationView(location: $location, allLocations: $viewModel.trip.locations)
                }
                
                Color.clear
                    .frame(height: 100)
                
                Spacer()
            }
        }
        .locationPicker(isPresented: $showingLocationPicker, selection: $viewModel.newLocation)
        .accessibilityHidden(showingTripPhoto)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 10) {
                    Button {
                        showingLocationPicker.toggle()
                    } label: {
                        Label("New Location", systemImage: "plus.circle")
                    }
                    
                    Menu {
                        Button(role: .destructive) {
                            dataController.delete(viewModel.trip)
                            dismiss()
                        } label: {
                            Label("Delete Trip", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Button {
                            withAnimation {
                                editingTrip = true
                                editingName = true
                            }
                        } label: {
                            Label("Edit Trip", systemImage: "pencil")
                        }
                        
                        if !viewModel.trip.allPhotos.isEmpty {
                            Button {
                                showingPhotosGrid.toggle()
                            } label: {
                                Label("Show All Photos", systemImage: "square.grid.2x2")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .disabled(showingTripPhoto || editingTrip)
            }
        }
        .background {
            NavigationLink(isActive: $showingPhotosGrid) {
                PhotosGridView(photos: viewModel.trip.allPhotos)
                    .navigationTitle(viewModel.trip.name)
            } label: {
                EmptyView()
            }
        }
        .overlay {
            if showingTripPhoto {
                PhotosTabView(photo: viewModel.trip.photo) {
                    withAnimation {
                        showingTripPhoto = false
                    }
                }
                .transition(.move(edge: .bottom))
                .background(.ultraThinMaterial)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingFullscreenMap) {
            FullscreenMapView(region: $viewModel.fullscreenMapRegion, locations: viewModel.trip.locations)
        }
        .onChange(of: newID) { id in
            guard let id = id else { return }
            
            withAnimation {
                viewModel.trip.photo = PhotoAsset(identifier: id)
            }
        }
        .onChange(of: viewModel.newLocation) { location in
            guard let location =  location else { return }
            
            withAnimation {
                viewModel.trip.append(location)
                viewModel.setRegion()
            }
        }
        .onChange(of: editingName) { _ in
            withAnimation {
                guard viewModel.trip.locations.isEmpty else { return }
                viewModel.setRegion()
            }
        }
        .onAppear {
            dataController.startCaching(viewModel.trip.allPhotos, targetSize: CGSize(width: 550, height: 550))
            viewModel.setRegion()
        }
        .onDisappear {
            dataController.stopCaching()
        }
    }
}

struct TripView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TripView(trip: .example)
                .environmentObject(DataController())
        }
    }
}
