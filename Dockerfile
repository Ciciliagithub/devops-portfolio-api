#Build file
FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src
COPY src/NotesApi/NotesApi.csproj /src/NotesApi/
RUN dotnet restore /src/NotesApi/NotesApi.csproj
COPY src/ /src/
RUN dotnet publish /src/NotesApi/NotesApi.csproj -c Release -o /app/publish

#.NET runtime image
FROM mcr.microsoft.com/dotnet/aspnet:11.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish /app/
EXPOSE 8080
USER $APP_UID
ENTRYPOINT ["dotnet", "NotesApi.dll"]